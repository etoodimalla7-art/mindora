"""
Section 18: description validation. Pure functions, no I/O, so they're
trivially unit-testable and reusable from both the API and (later) the
document-intelligence pipeline in Phase 5.
"""
import re

MIN_WORDS = 500
MAX_REPEATED_WORD_RATIO = 0.35  # if one word is >35% of all words, likely spam


def word_count(text: str) -> int:
    return len(re.findall(r"\b\w+\b", text))


def has_excessive_repetition(text: str) -> bool:
    words = re.findall(r"\b\w+\b", text.lower())
    if not words:
        return False
    from collections import Counter
    most_common_count = Counter(words).most_common(1)[0][1]
    return (most_common_count / len(words)) > MAX_REPEATED_WORD_RATIO


def validate_description(text: str) -> list[str]:
    """Returns a list of human-readable problems; empty list means valid."""
    problems: list[str] = []
    count = word_count(text)
    if count < MIN_WORDS:
        problems.append(f"Description must be at least {MIN_WORDS} words (currently {count}).")
    if has_excessive_repetition(text):
        problems.append("Description looks like repeated filler text rather than a real description.")
    return problems
