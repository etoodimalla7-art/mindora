"""
Sections 41-42: turns raw quiz/flashcard/mock-exam activity into
per-subject mastery scores and the 6-dimension readiness score. Pure
functions over plain lists/dicts — no DB access — so the aggregation
math is fully unit-testable; repository methods fetch the raw rows,
this module does the arithmetic.

Every "no data yet" case defaults to a LOW score, never a high one —
section 42 requires the readiness score to be an honest estimate, and
an empty state should never look like false confidence.
"""
from collections import defaultdict

WEAK_THRESHOLD = 50.0


def aggregate_quiz_scores_by_subject(attempts: list[tuple[str, float]]) -> dict[str, float]:
    """attempts: [(topic_title, score), ...] -> {topic_title: avg_score}"""
    buckets: dict[str, list[float]] = defaultdict(list)
    for topic, score in attempts:
        buckets[topic].append(score)
    return {topic: round(sum(scores) / len(scores), 1) for topic, scores in buckets.items()}


def aggregate_flashcard_known_ratio_by_subject(reviews: list[tuple[str, str]]) -> dict[str, float]:
    """reviews: [(topic_title, state), ...] -> {topic_title: known_ratio in [0,1]}"""
    buckets: dict[str, list[str]] = defaultdict(list)
    for topic, state in reviews:
        buckets[topic].append(state)
    return {topic: round(states.count("known") / len(states), 3) for topic, states in buckets.items()}


def compute_subject_mastery(avg_quiz_score: float | None, flashcard_known_ratio: float | None) -> float:
    """Blends quiz performance (60%) and flashcard retention (40%) for
    a subject when both exist; falls back to whichever signal exists;
    0.0 (not 50 or any 'neutral' guess) when neither does."""
    if avg_quiz_score is None and flashcard_known_ratio is None:
        return 0.0
    quiz_component = avg_quiz_score if avg_quiz_score is not None else 0.0
    flashcard_component = (flashcard_known_ratio * 100) if flashcard_known_ratio is not None else 0.0
    if avg_quiz_score is None:
        return round(flashcard_component, 1)
    if flashcard_known_ratio is None:
        return round(quiz_component, 1)
    return round((quiz_component * 0.6) + (flashcard_component * 0.4), 1)


def compute_all_subject_mastery(
    quiz_scores_by_subject: dict[str, float], flashcard_ratios_by_subject: dict[str, float]
) -> dict[str, float]:
    subjects = set(quiz_scores_by_subject) | set(flashcard_ratios_by_subject)
    return {
        subject: compute_subject_mastery(quiz_scores_by_subject.get(subject), flashcard_ratios_by_subject.get(subject))
        for subject in subjects
    }


def compute_weak_subject_ratio(mastery_by_subject: dict[str, float]) -> float:
    """No subjects with any recorded activity at all -> treat as 100%
    weak (honest default) rather than 0% weak, which would read as
    'nothing to worry about' for a student who hasn't started."""
    if not mastery_by_subject:
        return 1.0
    weak_count = sum(1 for score in mastery_by_subject.values() if score < WEAK_THRESHOLD)
    return weak_count / len(mastery_by_subject)


def compute_readiness(
    *,
    avg_quiz_score: float | None,
    quiz_attempt_count: int,
    flashcard_review_count: int,
    flashcard_known_ratio: float | None,
    avg_mock_exam_score: float | None,
    weak_subject_ratio: float,
    streak_days: int,
) -> dict[str, float]:
    knowledge = avg_quiz_score if avg_quiz_score is not None else 0.0
    # Practice: a simple volume-based scale (10 pts/quiz attempt, 2 pts/
    # flashcard review), capped at 100 — rewards doing the work without
    # needing a "correct" answer to count.
    practice = min(100.0, (quiz_attempt_count * 10) + (flashcard_review_count * 2))
    retention = (flashcard_known_ratio * 100) if flashcard_known_ratio is not None else 0.0
    # "Past Papers" dimension is proxied by mock-exam performance for
    # now — true past-paper-attempt tracking isn't built (past_papers
    # module only supports browsing/bookmarking, section 30), noted as
    # a gap rather than silently faked.
    past_papers = avg_mock_exam_score if avg_mock_exam_score is not None else 0.0
    weak_topics = round((1 - weak_subject_ratio) * 100, 1)
    consistency = min(100.0, streak_days * (100 / 14))  # a 14-day streak -> 100

    dimensions = {
        "knowledge": round(knowledge, 1),
        "practice": round(practice, 1),
        "retention": round(retention, 1),
        "past_papers": round(past_papers, 1),
        "weak_topics": weak_topics,
        "consistency": round(consistency, 1),
    }
    dimensions["overall"] = round(sum(dimensions.values()) / len(dimensions), 1)
    return dimensions
