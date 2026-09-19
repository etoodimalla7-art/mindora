"""
Sections 36-37: lets a student steer the tutor's teaching style mid-
conversation ("explain it more simply", "give me an example", "don't
give me the answer yet"). Pure keyword detection — same philosophy as
intent.py: fast, debuggable, not an LLM call for something this
mechanical. Detected adjustments MERGE into the conversation's stored
preferences (Conversation.style_preferences) rather than replacing
them, so a student who asked for "simpler" once stays in that mode
until they say otherwise — matching section 59's preference memory.
"""

_SIMPLER_PHRASES = ["explain it more simply", "simpler", "i don't understand", "explain like i'm", "easier", "more simply"]
_DETAILED_PHRASES = ["more detail", "in depth", "go deeper", "more detailed", "explain in depth"]
_UNIVERSITY_PHRASES = ["university level", "at university level", "advanced level"]
_EXAMPLE_PHRASES = ["give me an example", "another example", "show me an example"]
_STEPS_PHRASES = ["show me the steps", "step by step", "show the steps"]
_EXERCISE_PHRASES = ["give me an exercise", "give me a practice question", "quiz me"]
_SOCRATIC_ON_PHRASES = ["don't give me the answer", "do not give me the answer", "guide me", "socratic"]
_SOCRATIC_OFF_PHRASES = ["just tell me the answer", "give me the answer", "stop asking questions"]


def detect_style_request(text: str) -> dict:
    """Returns only the keys that changed — callers merge this into
    existing preferences, so an unrelated message (most messages) makes
    no change at all."""
    lowered = text.lower()
    updates: dict = {}

    if any(p in lowered for p in _SIMPLER_PHRASES):
        updates["depth"] = "simpler"
    elif any(p in lowered for p in _UNIVERSITY_PHRASES):
        updates["depth"] = "university"
    elif any(p in lowered for p in _DETAILED_PHRASES):
        updates["depth"] = "detailed"

    if any(p in lowered for p in _EXAMPLE_PHRASES):
        updates["want_example"] = True
    if any(p in lowered for p in _STEPS_PHRASES):
        updates["want_steps"] = True
    if any(p in lowered for p in _EXERCISE_PHRASES):
        updates["want_exercise"] = True

    if any(p in lowered for p in _SOCRATIC_ON_PHRASES):
        updates["socratic"] = True
    elif any(p in lowered for p in _SOCRATIC_OFF_PHRASES):
        updates["socratic"] = False

    return updates


def merge_style_preferences(existing: dict, updates: dict) -> dict:
    merged = dict(existing)
    merged.update(updates)
    return merged


def build_style_instructions(preferences: dict) -> str:
    """Turns stored preferences into an instruction block for the
    system prompt. Empty preferences -> empty string (no-op)."""
    instructions: list[str] = []

    depth = preferences.get("depth")
    if depth == "simpler":
        instructions.append("Explain in the simplest terms possible, as if to a beginner, avoiding jargon.")
    elif depth == "detailed":
        instructions.append("Give a thorough, detailed explanation.")
    elif depth == "university":
        instructions.append("Explain at a university/undergraduate level of rigor.")

    if preferences.get("want_example"):
        instructions.append("Include a concrete worked example.")
    if preferences.get("want_steps"):
        instructions.append("Break the explanation into clear numbered steps.")
    if preferences.get("want_exercise"):
        instructions.append("End with a practice exercise for the student to try.")

    if preferences.get("socratic"):
        instructions.append(
            "Use the Socratic method (section 37): do NOT give the final answer "
            "directly. Instead, ask guiding questions that lead the student to "
            "discover it themselves, one step at a time."
        )

    return " ".join(instructions)
