from datetime import datetime, timezone

from api.core.errors import NotFoundError
from api.modules.progress.analytics import (
    aggregate_flashcard_known_ratio_by_subject,
    aggregate_quiz_scores_by_subject,
    compute_all_subject_mastery,
    compute_readiness,
    compute_weak_subject_ratio,
)


def compute_streak(completed_at_list: list[datetime]) -> int:
    """
    Consecutive-day streak ending today or yesterday (so a streak isn't
    lost just because today's session hasn't happened yet). Section 13/51.
    """
    if not completed_at_list:
        return 0
    days = sorted({dt.astimezone(timezone.utc).date() for dt in completed_at_list}, reverse=True)
    today = datetime.now(timezone.utc).date()
    if days[0] not in (today, today.fromordinal(today.toordinal() - 1)):
        return 0
    streak = 1
    for i in range(len(days) - 1):
        if (days[i] - days[i + 1]).days == 1:
            streak += 1
        else:
            break
    return streak


class ProgressService:
    """
    Computes progress/readiness LIVE from quiz/flashcard/mock-exam
    activity on every request, rather than reading a maintained cache —
    the `progress`/`readiness_scores` tables from the original DB
    schema exist but are deliberately not written to yet. That trades
    a small amount of per-request computation (all small-scale, student-
    sized data) for a guarantee that the number shown is never stale.
    Persisted history for trend charts (section 41's "improvement
    trends") is a later-phase addition once this shape is proven.
    """

    def __init__(self, sessions_repo, quizzes_repo, flashcards_repo, mock_exams_repo):
        self.sessions_repo = sessions_repo
        self.quizzes_repo = quizzes_repo
        self.flashcards_repo = flashcards_repo
        self.mock_exams_repo = mock_exams_repo

    async def _subject_mastery(self, user_id: str) -> dict[str, float]:
        quiz_attempts = await self.quizzes_repo.list_attempts_with_quiz_topic_for_user(user_id)
        flashcard_reviews = await self.flashcards_repo.list_reviews_with_topic_for_user(user_id)
        quiz_scores = aggregate_quiz_scores_by_subject(quiz_attempts)
        flashcard_ratios = aggregate_flashcard_known_ratio_by_subject(flashcard_reviews)
        return compute_all_subject_mastery(quiz_scores, flashcard_ratios)

    async def get_overview(self, user_id: str) -> dict:
        mastery_by_subject = await self._subject_mastery(user_id)
        completed_dates = await self.sessions_repo.get_completed_dates(user_id)
        streak = compute_streak(completed_dates)
        subjects_sorted = sorted(mastery_by_subject.items(), key=lambda kv: kv[1])
        weakest = subjects_sorted[0][0] if subjects_sorted else None
        return {
            "streak_days": streak,
            "subjects": [
                {"subject_name": name, "mastery_score": score, "last_studied_at": None}
                for name, score in subjects_sorted
            ],
            "weakest_subject": weakest,
        }

    async def get_readiness(self, user_id: str, target_exam_name: str) -> dict:
        quiz_attempts = await self.quizzes_repo.list_attempts_with_quiz_topic_for_user(user_id)
        flashcard_reviews = await self.flashcards_repo.list_reviews_with_topic_for_user(user_id)
        mock_attempts = await self.mock_exams_repo.list_attempts_for_user(user_id)

        if not quiz_attempts and not flashcard_reviews and not mock_attempts:
            raise NotFoundError(
                "Your readiness score will appear once you start studying and practicing."
            )

        quiz_scores_by_subject = aggregate_quiz_scores_by_subject(quiz_attempts)
        flashcard_ratios_by_subject = aggregate_flashcard_known_ratio_by_subject(flashcard_reviews)
        mastery_by_subject = compute_all_subject_mastery(quiz_scores_by_subject, flashcard_ratios_by_subject)
        weak_ratio = compute_weak_subject_ratio(mastery_by_subject)

        avg_quiz_score = round(sum(s for _, s in quiz_attempts) / len(quiz_attempts), 1) if quiz_attempts else None
        flashcard_states = [state for _, state in flashcard_reviews]
        flashcard_known_ratio = (
            flashcard_states.count("known") / len(flashcard_states) if flashcard_states else None
        )
        avg_mock_exam_score = (
            round(sum(a.score for a in mock_attempts) / len(mock_attempts), 1) if mock_attempts else None
        )

        completed_dates = await self.sessions_repo.get_completed_dates(user_id)
        streak = compute_streak(completed_dates)

        dimensions = compute_readiness(
            avg_quiz_score=avg_quiz_score,
            quiz_attempt_count=len(quiz_attempts),
            flashcard_review_count=len(flashcard_reviews),
            flashcard_known_ratio=flashcard_known_ratio,
            avg_mock_exam_score=avg_mock_exam_score,
            weak_subject_ratio=weak_ratio,
            streak_days=streak,
        )
        return {"target_exam_name": target_exam_name, **dimensions, "computed_at": datetime.now(timezone.utc)}
