"""Validates a document description against the minimum-words rule and anti-spam."""
from __future__ import annotations

import re
from dataclasses import dataclass

# Reduced thresholds — 20 words is enough for a meaningful description.
MIN_WORDS = 20
MIN_UNIQUE_WORDS = 8
MIN_CHARACTERS = 60
MAX_REPETITION_RATIO = 0.85  # >85% repeated content words → reject

STOP_WORDS = {
    # English
    "the", "a", "an", "and", "or", "of", "to", "in", "on", "for", "at",
    "is", "are", "was", "were", "be", "been", "being", "am",
    "this", "that", "these", "those", "with", "by", "from", "as",
    "it", "its", "it's", "i", "you", "he", "she", "we", "they",
    "his", "her", "their", "our", "your", "my", "me", "us", "them",
    "not", "but", "if", "then", "than", "so", "such", "there", "here",
    "has", "have", "had", "do", "does", "did", "will", "would", "can",
    "could", "should", "may", "might", "must", "shall",
    "into", "about", "over", "under", "between", "through",
    # French
    "le", "la", "les", "un", "une", "des", "du", "de", "et", "est",
    "sont", "être", "avoir", "pour", "avec", "dans", "sur", "que",
    "qui", "pas", "plus", "ce", "cette", "ces", "il", "elle", "ils",
    "elles", "nous", "vous", "je", "tu", "au", "aux", "par", "en",
    "se", "sa", "son", "ses", "mon", "ma", "mes", "ton", "ta", "tes",
    "ou", "où", "donc", "mais", "si", "comme", "tout", "tous", "aussi",
    "peut", "doit", "fait", "faire", "cet", "leur", "leurs",
}


@dataclass
class DescriptionValidationResult:
    passed: bool
    word_count: int
    unique_word_count: int
    repetition_ratio: float
    failure_reason: str | None = None


def validate_description(text: str | None) -> DescriptionValidationResult:
    if not text or not text.strip():
        return DescriptionValidationResult(
            passed=False,
            word_count=0,
            unique_word_count=0,
            repetition_ratio=0.0,
            failure_reason="Description is empty.",
        )

    stripped = text.strip()
    if len(stripped) < MIN_CHARACTERS:
        return DescriptionValidationResult(
            passed=False,
            word_count=0,
            unique_word_count=0,
            repetition_ratio=0.0,
            failure_reason=(
                f"Description is too short. Please write at least "
                f"{MIN_CHARACTERS} characters."
            ),
        )

    if re.search(r"(.)\1{9,}", stripped):
        return DescriptionValidationResult(
            passed=False,
            word_count=0,
            unique_word_count=0,
            repetition_ratio=0.0,
            failure_reason=(
                "The description contains too many repeated characters. "
                "Please describe the document in your own words."
            ),
        )
    if re.search(r"[!?]{6,}", stripped):
        return DescriptionValidationResult(
            passed=False,
            word_count=0,
            unique_word_count=0,
            repetition_ratio=0.0,
            failure_reason=(
                "The description looks like spam. Please write a meaningful "
                "summary of the document."
            ),
        )

    all_tokens = re.findall(r"\b[\wÀ-ÿ'-]+\b", stripped.lower())
    word_count = len(all_tokens)

    if word_count < MIN_WORDS:
        return DescriptionValidationResult(
            passed=False,
            word_count=word_count,
            unique_word_count=len(set(all_tokens)),
            repetition_ratio=0.0,
            failure_reason=(
                f"Description must contain at least {MIN_WORDS} words "
                f"(got {word_count})."
            ),
        )

    content_tokens = [t for t in all_tokens if t not in STOP_WORDS]
    if not content_tokens:
        return DescriptionValidationResult(
            passed=False,
            word_count=word_count,
            unique_word_count=0,
            repetition_ratio=1.0,
            failure_reason=(
                "The description is only made of common words. Please write "
                "a meaningful description of the document."
            ),
        )

    unique_content = set(content_tokens)
    unique_count = len(unique_content)
    repetition_ratio = 1.0 - (unique_count / len(content_tokens))

    if unique_count < MIN_UNIQUE_WORDS:
        return DescriptionValidationResult(
            passed=False,
            word_count=word_count,
            unique_word_count=unique_count,
            repetition_ratio=round(repetition_ratio, 3),
            failure_reason=(
                "The description repeats too many words. Please describe the "
                "document with more variety."
            ),
        )

    if repetition_ratio > MAX_REPETITION_RATIO:
        return DescriptionValidationResult(
            passed=False,
            word_count=word_count,
            unique_word_count=unique_count,
            repetition_ratio=round(repetition_ratio, 3),
            failure_reason=(
                "The description looks repetitive. Please describe the "
                "document in your own words."
            ),
        )

    return DescriptionValidationResult(
        passed=True,
        word_count=word_count,
        unique_word_count=unique_count,
        repetition_ratio=round(repetition_ratio, 3),
    )
