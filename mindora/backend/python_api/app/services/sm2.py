"""SuperMemo 2 (SM-2) spaced repetition algorithm.

Reference: https://super-memory.com/english/ol/sm2.htm

Quality (0-5):
  0 = Complete blackout
  1 = Incorrect; correct answer remembered after seeing it
  2 = Incorrect; correct answer seemed easy to recall
  3 = Correct with serious difficulty
  4 = Correct after hesitation
  5 = Perfect recall

Returns updated (ease_factor, interval_days, repetitions).
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone


@dataclass
class SM2Result:
    ease_factor: float
    interval_days: int
    repetitions: int
    next_review_at: datetime


def update_sm2(
    *,
    current_ease: float,
    current_interval: int,
    current_repetitions: int,
    quality: int,
    now: datetime | None = None,
) -> SM2Result:
    """Apply SM-2 update for a single card review.

    quality must be 0..5 (higher = easier).
    """
    if not 0 <= quality <= 5:
        raise ValueError("quality must be between 0 and 5")

    now = now or datetime.now(timezone.utc)

    # --- Update ease factor ---
    # EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    new_ease = current_ease + (
        0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)
    )
    # Floor at 1.3 (hardest possible)
    new_ease = max(1.3, new_ease)

    # --- Update repetitions & interval ---
    if quality < 3:
        # Failed → reset
        new_reps = 0
        new_interval = 1
    else:
        new_reps = current_repetitions + 1
        if new_reps == 1:
            new_interval = 1
        elif new_reps == 2:
            new_interval = 6
        else:
            new_interval = round(current_interval * new_ease)

    next_review = now + timedelta(days=new_interval)

    return SM2Result(
        ease_factor=round(new_ease, 2),
        interval_days=new_interval,
        repetitions=new_reps,
        next_review_at=next_review,
    )
