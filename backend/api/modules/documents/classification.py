"""
Section 21 pipeline steps: content classification / subject detection /
level detection. This is a keyword-frequency heuristic (v1) — cheap,
dependency-free, and good enough to flag obvious metadata mismatches for
human review. Swap for an embedding-based classifier once there's a
labeled corpus to train/prompt against; nothing outside this file needs
to change (same `detect_subject`/`detect_level` signatures).
"""
import re

_CATEGORY_KEYWORDS: dict[str, list[str]] = {
    "Mathematics": ["equation", "derivative", "integral", "algebra", "geometry", "theorem", "matrix", "calculus"],
    "Physics": ["force", "velocity", "energy", "newton", "quantum", "circuit", "acceleration", "electric field"],
    "Chemistry": ["reaction", "molecule", "acid", "compound", "periodic table", "solution", "catalyst"],
    "Biology": ["cell", "organism", "photosynthesis", "genetics", "ecosystem", "enzyme", "chromosome"],
    "Computer Science": ["algorithm", "function", "variable", "database", "network protocol", "compiler", "recursion"],
    "Economics": ["supply", "demand", "inflation", "gdp", "market", "monetary policy"],
    "Accounting": ["ledger", "balance sheet", "debit", "credit", "depreciation", "journal entry"],
    "History": ["century", "revolution", "empire", "treaty", "colonial"],
    "Geography": ["climate", "continent", "population density", "erosion", "latitude"],
}

_LEVEL_KEYWORDS: dict[str, list[str]] = {
    "Primary": ["primary school", "class one", "class two"],
    "Secondary": ["form one", "form two", "form three", "form four", "form five", "gce"],
    "University": ["university", "faculty", "undergraduate", "lecture", "semester"],
    "HND": ["hnd", "higher national diploma"],
    "BTS": ["bts", "brevet de technicien"],
    "Licence": ["licence", "l1", "l2", "l3"],
    "Master": ["master's", "m1", "m2", "thesis"],
}


def _score_keywords(lowered_text: str, keyword_map: dict[str, list[str]]) -> dict[str, int]:
    return {label: sum(lowered_text.count(kw) for kw in kws) for label, kws in keyword_map.items()}


def detect_subject(text: str) -> str | None:
    lowered = text.lower()
    scores = _score_keywords(lowered, _CATEGORY_KEYWORDS)
    best = max(scores, key=scores.get)
    return best if scores[best] > 0 else None


def detect_level(text: str) -> str | None:
    lowered = text.lower()
    scores = _score_keywords(lowered, _LEVEL_KEYWORDS)
    best = max(scores, key=scores.get)
    return best if scores[best] > 0 else None


def compute_quality_score(text: str) -> float:
    """0-100 heuristic: mostly a proxy for "is there enough real content
    here at all" — a fuller quality model (structure, headings, coverage)
    is a later refinement, same interface."""
    word_count = len(re.findall(r"\b\w+\b", text))
    return round(min(100.0, word_count / 20), 1)  # ~2000 words -> 100
