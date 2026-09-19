"""
Section 38: spaced-repetition scheduling. Deliberately a simple,
well-understood progression (not full SM-2) so behavior is predictable
and testable: "known" grows the interval (capped), "uncertain" resets
to a short fixed interval, "forgotten" comes back the same day.
"""
from datetime import datetime, timedelta, timezone

# Days until next review after N consecutive "known" reviews in a row.
_KNOWN_INTERVALS_DAYS = [1, 2, 4, 7, 14, 30]


def compute_next_due(state: str, consecutive_known: int) -> tuple[datetime, int]:
    """Returns (next_due_at, updated_consecutive_known_streak)."""
    now = datetime.now(timezone.utc)

    if state == "known":
        new_streak = consecutive_known + 1
        index = min(new_streak - 1, len(_KNOWN_INTERVALS_DAYS) - 1)
        return now + timedelta(days=_KNOWN_INTERVALS_DAYS[index]), new_streak

    if state == "uncertain":
        return now + timedelta(days=1), 0

    if state == "forgotten":
        return now + timedelta(hours=4), 0

    raise ValueError(f"Unknown review state: {state!r}")
