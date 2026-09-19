"""
Sections 38-39: flashcard and quiz generation, v1. Real LLM-based
generation (rephrasing content into well-formed questions, drawing on
broader context) needs a configured LLMProvider and structured-output
parsing — the natural upgrade path once that's tested against a real
key (see ARCHITECTURE.md's Replaceability Matrix). This v1 is a
deterministic, dependency-free extractor over a document's
already-extracted text, so generation works from day one with no API
key and is fully unit-testable — same philosophy as classification.py
(Phase 5) and generation.py (Phase 7).
"""
import re

_DEFINITION_PATTERN = re.compile(
    r"^(.{3,60}?)\s+(?:is|are|refers to|means)\s+(.{10,220})$", re.IGNORECASE
)

# Pronouns and other non-term words that grammatically fit "X is Y" but
# are never a real flashcard subject — without this filter, a sentence
# like "This is not a great example" gets extracted as if "This" were
# the term being defined.
_NON_TERM_WORDS = {
    "this", "that", "these", "those", "it", "he", "she", "they", "there",
    "here", "what", "which", "who", "one", "some", "such", "the",
}


def _split_sentences(text: str) -> list[str]:
    return [s.strip() for s in re.split(r"(?<=[.!?])\s+", text) if len(s.strip()) > 15]


def extract_definition_pairs(text: str) -> list[tuple[str, str]]:
    """Finds sentences shaped like 'X is Y' and returns (term, definition)
    pairs. Deliberately conservative — a few good pairs beat many noisy
    ones, and a term with more than 6 words (or that's just a pronoun)
    is almost always a mis-parsed clause, not a real term."""
    pairs = []
    for sentence in _split_sentences(text):
        match = _DEFINITION_PATTERN.match(sentence)
        if match:
            term = match.group(1).strip()
            definition = match.group(2).strip().rstrip(".")
            term_words = term.lower().split()
            if 0 < len(term_words) <= 6 and term_words[-1] not in _NON_TERM_WORDS:
                pairs.append((term, definition))
    return pairs


def generate_flashcards_from_text(text: str, topic_title: str, max_cards: int = 10) -> list[dict]:
    pairs = extract_definition_pairs(text)[:max_cards]
    if not pairs:
        # No clean "X is Y" sentences found (no document, or dense prose
        # without that phrasing) -> one generic review card, never zero.
        return [{
            "front": f"What are the key ideas of {topic_title}?",
            "back": "Review your notes and summarize the main points in your own words.",
            "type": "concept",
        }]
    return [{"front": f"What is {term}?", "back": definition, "type": "definition"} for term, definition in pairs]
