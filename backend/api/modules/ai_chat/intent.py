"""
Section 15's TOOL SELECTION step, Phase 8 scope: heuristic keyword
rules rather than an LLM call, so routing is instant, free, and
debuggable ("the AI must not use every tool for every question"). A
model-based classifier can replace this later behind the same
`classify_intent(text) -> str` signature — nothing downstream needs to
change.
"""

_GREETINGS = {
    "hi", "hello", "hey", "yo", "good morning", "good afternoon", "good evening",
    "bonjour", "salut", "bonsoir",
}


def classify_intent(text: str) -> str:
    lowered = text.strip().lower().rstrip("!.?")
    if not lowered:
        return "empty"
    if lowered in _GREETINGS or any(lowered.startswith(g + " ") for g in _GREETINGS):
        return "greeting"
    return "question"
