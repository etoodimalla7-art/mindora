"""Document analysis: language detection, subject classification, quality.

Primary path: Gemini with strict JSON output.
Fallback path: heuristic inference from metadata and text.

The service never raises on AI failure — it degrades gracefully so an
unavailable provider does not block a user from submitting a document.
"""
from __future__ import annotations

import json
import logging
import re
from collections import Counter
from dataclasses import dataclass, field

from app.core.config import settings
from app.integrations.ai.factory import get_chat_provider
from app.integrations.ai.provider import ChatMessage

logger = logging.getLogger(__name__)

# Languages we recognize.
SUPPORTED_LANGUAGES = ("en", "fr")

# Common French stopwords — used by the heuristic language detector.
FRENCH_MARKERS = {
    "le", "la", "les", "un", "une", "des", "du", "de", "et", "est",
    "pour", "avec", "dans", "sur", "que", "qui", "pas", "plus", "ce",
    "cette", "sont", "être", "avoir", "mais", "ou", "où", "donc",
}

# Common English stopwords.
ENGLISH_MARKERS = {
    "the", "a", "an", "and", "or", "of", "to", "in", "on", "for",
    "is", "are", "was", "were", "be", "been", "this", "that", "these",
    "those", "with", "by", "not", "but", "if", "then", "than",
}


@dataclass
class AnalysisResult:
    detected_language: str | None = None
    language_confidence: float = 0.0
    detected_subject: str | None = None
    subject_confidence: float = 0.0
    detected_level: str | None = None
    level_confidence: float = 0.0
    detected_doc_type: str | None = None
    doc_type_confidence: float = 0.0
    is_spam: bool = False
    is_inappropriate: bool = False
    contains_pii: bool = False
    quality_score: float = 0.0
    keywords: list[str] = field(default_factory=list)
    summary: str | None = None
    raw_response: dict = field(default_factory=dict)


async def analyze_document(
    *,
    text: str,
    title: str,
    description: str,
    declared_language: str | None = None,
    declared_subject: str | None = None,
    declared_level: str | None = None,
) -> AnalysisResult:
    """Run AI analysis, then merge with heuristic signals."""
    # 1. Heuristics from the description (always available).
    heuristic_lang, lang_conf = _detect_language(description or text)
    heuristic_keywords = _extract_keywords(description)
    heuristic_spam = _looks_like_spam(description)

    # 2. Try the LLM for a richer classification.
    ai_result: AnalysisResult | None = None
    if settings.GEMINI_API_KEY:
        ai_result = await _run_llm_classification(
            text=text[:8000],  # cap to keep token usage sane
            title=title,
            description=description,
        )

    # 3. Merge.
    if ai_result is not None:
        result = ai_result
        # Prefer the LLM language if it's confident, else heuristic.
        if result.detected_language is None:
            result.detected_language = heuristic_lang
            result.language_confidence = lang_conf
    else:
        result = AnalysisResult(
            detected_language=heuristic_lang,
            language_confidence=lang_conf,
            keywords=heuristic_keywords,
            is_spam=heuristic_spam,
        )

    # 4. Sanity-fill from declared metadata when the AI missed it.
    if not result.detected_subject and declared_subject:
        result.detected_subject = declared_subject
        result.subject_confidence = 0.4
    if not result.detected_level and declared_level:
        result.detected_level = declared_level
        result.level_confidence = 0.4
    if not result.detected_language and declared_language:
        result.detected_language = declared_language
        result.language_confidence = 0.4
    if not result.keywords:
        result.keywords = heuristic_keywords

    # 5. Compute a quality score.
    result.quality_score = _quality_score(
        text=text,
        description=description,
        analysis=result,
    )

    return result


# ---------- Heuristics ----------

def _detect_language(text: str) -> tuple[str | None, float]:
    if not text:
        return None, 0.0
    tokens = re.findall(r"\b[a-zA-ZÀ-ÿ]+\b", text.lower())
    if not tokens:
        return None, 0.0
    counts = Counter(tokens)
    french_hits = sum(counts[w] for w in FRENCH_MARKERS)
    english_hits = sum(counts[w] for w in ENGLISH_MARKERS)
    total = french_hits + english_hits
    if total == 0:
        return None, 0.0
    if french_hits > english_hits:
        return "fr", min(french_hits / total, 1.0)
    if english_hits > french_hits:
        return "en", min(english_hits / total, 1.0)
    return None, 0.0


def _extract_keywords(text: str, top_n: int = 12) -> list[str]:
    if not text:
        return []
    stop = FRENCH_MARKERS | ENGLISH_MARKERS
    tokens = re.findall(r"\b[a-zA-ZÀ-ÿ]{4,}\b", text.lower())
    counts = Counter(t for t in tokens if t not in stop)
    return [w for w, _ in counts.most_common(top_n)]


def _looks_like_spam(description: str) -> bool:
    """Cheap anti-spam: short, all-caps, or extreme repetition."""
    if not description:
        return True
    stripped = description.strip()
    if len(stripped) < 200:
        return True
    # Too many consecutive identical characters.
    if re.search(r"(.)\1{7,}", stripped):
        return True
    # Too many exclamation/question marks in a row.
    if re.search(r"[!?]{5,}", stripped):
        return True
    return False


def _quality_score(*, text: str, description: str, analysis: AnalysisResult) -> float:
    """Composite 0..1 score combining length, coverage, confidence."""
    score = 0.0
    if text:
        score += min(len(text) / 5000, 1.0) * 0.4
    if description:
        words = len(description.split())
        score += min(words / 500, 1.0) * 0.3
    confidences = [
        analysis.language_confidence,
        analysis.subject_confidence,
        analysis.level_confidence,
    ]
    non_zero = [c for c in confidences if c > 0]
    if non_zero:
        score += (sum(non_zero) / len(non_zero)) * 0.3
    return round(score, 3)


# ---------- LLM ----------

_SYSTEM_PROMPT = """You analyze educational documents for a study platform.
You will receive a title, a description, and the extracted text of a document.
Return strictly a single JSON object with these keys:

  detected_language : "en" or "fr" (ISO 639-1) or null
  language_confidence : number 0..1
  detected_subject : a short subject label (e.g. "Mathematics", "Physics",
                     "Chemistry", "Biology", "Computer Science", "Economics",
                     "Accounting", "English", "French", "History", "Geography",
                     "Philosophy") or null
  subject_confidence : number 0..1
  detected_level : one of "PRIMARY", "SECONDARY", "GCE_OL", "GCE_AL", "BEPC",
                   "PROBATOIRE", "BACCALAUREAT", "HND", "BTS", "LICENCE",
                   "MASTER", "UNIVERSITY" or null
  level_confidence : number 0..1
  detected_doc_type : one of "course_notes", "past_paper", "study_guide",
                      "exercise_set", "textbook", "summary", "unknown"
  doc_type_confidence : number 0..1
  is_spam : boolean
  is_inappropriate : boolean
  contains_pii : boolean
  keywords : array of up to 12 short strings
  summary : a 1-2 sentence summary in the document's language

Return ONLY the JSON object. No prose, no markdown fences."""


async def _run_llm_classification(
    *, text: str, title: str, description: str
) -> AnalysisResult | None:
    try:
        provider = get_chat_provider()
        user_prompt = (
            f"TITLE:\n{title}\n\n"
            f"DESCRIPTION:\n{description}\n\n"
            f"EXTRACTED TEXT (truncated):\n{text}\n"
        )
        response = await provider.chat(
            [
                ChatMessage(role="system", content=_SYSTEM_PROMPT),
                ChatMessage(role="user", content=user_prompt),
            ],
            temperature=0.1,
            json_mode=True,
            max_tokens=800,
        )
        data = _parse_json(response.content)
        if data is None:
            return None
        return AnalysisResult(
            detected_language=_short(data.get("detected_language"), 8),
            language_confidence=_conf(data.get("language_confidence")),
            detected_subject=_short(data.get("detected_subject"), 80),
            subject_confidence=_conf(data.get("subject_confidence")),
            detected_level=_short(data.get("detected_level"), 40),
            level_confidence=_conf(data.get("level_confidence")),
            detected_doc_type=_short(data.get("detected_doc_type"), 60),
            doc_type_confidence=_conf(data.get("doc_type_confidence")),
            is_spam=bool(data.get("is_spam", False)),
            is_inappropriate=bool(data.get("is_inappropriate", False)),
            contains_pii=bool(data.get("contains_pii", False)),
            keywords=[str(k)[:32] for k in (data.get("keywords") or [])][:12],
            summary=_short(data.get("summary"), 400),
            raw_response={"provider": "gemini", "raw": data},
        )
    except Exception as exc:  # noqa: BLE001
        logger.warning("llm_classification_failed error=%s", exc)
        return None


def _parse_json(text: str) -> dict | None:
    """Parse a JSON object out of a possibly noisy LLM response."""
    if not text:
        return None
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # Try to extract the first {...} block.
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if not match:
            return None
        try:
            return json.loads(match.group(0))
        except json.JSONDecodeError:
            return None


def _short(v, max_len: int) -> str | None:
    if v is None:
        return None
    s = str(v).strip()
    if not s:
        return None
    return s[:max_len]


def _conf(v) -> float:
    try:
        f = float(v)
    except (TypeError, ValueError):
        return 0.0
    return max(0.0, min(1.0, f))
