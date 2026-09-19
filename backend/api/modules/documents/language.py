"""Section 20: language declared vs. detected — flag, don't silently trust."""

_LANGUAGE_NAMES = {"en": "English", "fr": "French"}


def detect_language(text: str) -> str | None:
    cleaned = text.strip()
    if len(cleaned) < 40:  # too short to detect reliably — don't guess
        return None
    try:
        from langdetect import DetectorFactory, detect

        DetectorFactory.seed = 0  # deterministic results
        return detect(cleaned)
    except Exception:
        return None


def check_language_mismatch(declared: str | None, detected: str | None) -> str | None:
    """Returns a human-readable mismatch message, or None if consistent
    (or if either side isn't one of our two supported languages, in
    which case we don't have grounds to flag it)."""
    if not declared or not detected:
        return None
    if declared not in _LANGUAGE_NAMES or detected not in _LANGUAGE_NAMES:
        return None
    if declared == detected:
        return None
    return (
        f"You selected {_LANGUAGE_NAMES[declared]}, but this document looks "
        f"like it's mostly {_LANGUAGE_NAMES[detected]}. Please correct the "
        "language or upload the right file."
    )
