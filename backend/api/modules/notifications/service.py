from datetime import date, datetime, timezone

from api.modules.notifications.generation import (
    build_exam_countdown_reminder,
    build_missed_session_reminder,
    build_upcoming_session_reminder,
    is_within_quiet_hours,
)
from api.modules.progress.analytics import aggregate_flashcard_known_ratio_by_subject, aggregate_quiz_scores_by_subject, compute_all_subject_mastery

UPCOMING_WINDOW_MINUTES = 15
MISSED_GRACE_MINUTES = 60


class NotificationsService:
    def __init__(self, repo, sessions_repo, planner_repo, quizzes_repo, flashcards_repo):
        self.repo = repo
        self.sessions_repo = sessions_repo
        self.planner_repo = planner_repo
        self.quizzes_repo = quizzes_repo
        self.flashcards_repo = flashcards_repo

    async def get_preferences(self, user_id: str):
        return await self.repo.get_or_create_preferences(user_id)

    async def update_preferences(self, user_id: str, data: dict):
        return await self.repo.update_preferences(user_id, data)

    async def _weakest_subject(self, user_id: str) -> str | None:
        quiz_attempts = await self.quizzes_repo.list_attempts_with_quiz_topic_for_user(user_id)
        flashcard_reviews = await self.flashcards_repo.list_reviews_with_topic_for_user(user_id)
        mastery = compute_all_subject_mastery(
            aggregate_quiz_scores_by_subject(quiz_attempts),
            aggregate_flashcard_known_ratio_by_subject(flashcard_reviews),
        )
        return min(mastery, key=mastery.get) if mastery else None

    async def generate_for_user(self, user_id: str) -> list:
        """Section 47: called whenever the notification center is
        opened (no scheduler/push infrastructure exists yet — see
        ROADMAP.md) — scans current state and creates any notifications
        that are due and not already generated. Safe to call
        repeatedly: dedup keys prevent duplicates, and disabled
        preferences or quiet hours produce an empty list without error.
        """
        prefs = await self.get_preferences(user_id)
        if not prefs.enabled:
            return []
        now = datetime.now(timezone.utc)
        if is_within_quiet_hours(now, prefs.quiet_hours_start, prefs.quiet_hours_end):
            return []

        created = []

        upcoming = await self.sessions_repo.get_upcoming_within(user_id, UPCOMING_WINDOW_MINUTES)
        for session in upcoming:
            if await self.repo.exists_with_payload_value(user_id, "session_upcoming", "session_id", str(session.id)):
                continue
            content = build_upcoming_session_reminder(session.subject_name, session.topic_title, UPCOMING_WINDOW_MINUTES)
            created.append(await self.repo.create(
                user_id, content["type"], content["title"], content["body"], {"session_id": str(session.id)}, now,
            ))

        missed = await self.sessions_repo.get_missed(user_id, MISSED_GRACE_MINUTES)
        for session in missed:
            if await self.repo.exists_with_payload_value(user_id, "session_missed", "session_id", str(session.id)):
                continue
            content = build_missed_session_reminder(session.subject_name, session.topic_title)
            created.append(await self.repo.create(
                user_id, content["type"], content["title"], content["body"], {"session_id": str(session.id)}, now,
            ))

        plan = await self.planner_repo.get_latest_active_exam_plan(user_id)
        if plan and plan.target_exam_name:
            days_remaining = (plan.end_date - date.today()).days
            dedupe_value = f"{plan.id}:{date.today().isoformat()}"
            already_sent_today = await self.repo.exists_with_payload_value(
                user_id, "exam_countdown", "plan_day", dedupe_value
            )
            if days_remaining >= 0 and not already_sent_today:
                weakest = await self._weakest_subject(user_id)
                content = build_exam_countdown_reminder(plan.target_exam_name, days_remaining, weakest)
                created.append(await self.repo.create(
                    user_id, content["type"], content["title"], content["body"], {"plan_day": dedupe_value}, now,
                ))

        return created

    async def list_notifications(self, user_id: str):
        await self.generate_for_user(user_id)  # always fresh — see generate_for_user's docstring
        return await self.repo.list_for_user(user_id)

    async def mark_read(self, notification_id: str, user_id: str):
        return await self.repo.mark_read(notification_id, user_id, datetime.now(timezone.utc))
