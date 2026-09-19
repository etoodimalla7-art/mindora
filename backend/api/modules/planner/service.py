from datetime import date, datetime, timedelta, timezone

from api.core.errors import NotFoundError, ValidationFailedError
from api.modules.catalog.repository import CatalogRepository
from api.modules.planner.generation import FALLBACK_TOPIC, build_session_plan
from api.modules.planner.repository import PlannerRepository
from api.modules.planner.schemas import CreateExamPlanIn, CreateSubjectPlanIn

# Early-evening default; section 47 lets students set a preferred study
# time later — this is just the seed value until that preference exists.
DEFAULT_SESSION_HOUR = 18


def _session_datetime(day: date, hour: int = DEFAULT_SESSION_HOUR) -> datetime:
    return datetime.combine(day, datetime.min.time(), tzinfo=timezone.utc).replace(hour=hour)


class PlannerService:
    def __init__(self, repo: PlannerRepository, catalog_repo: CatalogRepository):
        self.repo = repo
        self.catalog_repo = catalog_repo

    async def _topics_for_subject(self, subject_name: str) -> tuple[str | None, list[dict]]:
        subject = await self.catalog_repo.get_subject_by_name(subject_name)
        if not subject:
            return None, [FALLBACK_TOPIC]
        topics = await self.catalog_repo.list_topics_for_subject(str(subject.id))
        if not topics:
            return str(subject.id), [FALLBACK_TOPIC]
        return str(subject.id), [{"title": t.title, "id": str(t.id)} for t in topics]

    def _to_sessions_data(self, raw_plan: list[dict], subject_ids: dict[str, str | None],
                           start: date, minutes_per_session: int) -> list[dict]:
        return [
            {
                "subject_id": subject_ids[item["subject_name"]],
                "topic_id": item["topic_id"],
                "subject_name": item["subject_name"],
                "topic_title": item["topic_title"],
                "scheduled_at": _session_datetime(start + timedelta(days=item["day_offset"])),
                "duration_minutes": minutes_per_session,
            }
            for item in raw_plan
        ]

    async def create_exam_plan(self, user_id: str, payload: CreateExamPlanIn):
        today = date.today()
        total_days = (payload.exam_date - today).days
        if total_days < 1:
            raise ValidationFailedError("Your exam date needs to be in the future.")

        subjects_topics: dict[str, list[dict]] = {}
        subject_ids: dict[str, str | None] = {}
        for name in payload.subject_names:
            subject_id, topics = await self._topics_for_subject(name)
            subjects_topics[name] = topics
            subject_ids[name] = subject_id

        raw_plan = build_session_plan(subjects_topics, total_days)
        plan = await self.repo.create_plan(
            user_id, "exam", payload.target_exam_name, payload.subject_names, today, payload.exam_date,
        )
        sessions_data = self._to_sessions_data(raw_plan, subject_ids, today, payload.minutes_per_session)
        sessions = await self.repo.bulk_create_sessions(str(plan.id), user_id, sessions_data)
        return plan, sessions

    async def create_subject_plan(self, user_id: str, payload: CreateSubjectPlanIn):
        subject_id, topics = await self._topics_for_subject(payload.subject_name)
        if payload.topic_title:
            # Student named a specific topic -> a focused revision plan
            # that repeats it, rather than cycling the whole catalog.
            topics = [{"title": payload.topic_title, "id": None}]

        raw_plan = build_session_plan({payload.subject_name: topics}, payload.duration_days)
        today = date.today()
        end_date = today + timedelta(days=payload.duration_days - 1)
        plan = await self.repo.create_plan(
            user_id, "subject", None, [payload.subject_name], today, end_date,
        )
        sessions_data = self._to_sessions_data(
            raw_plan, {payload.subject_name: subject_id}, today, payload.minutes_per_session
        )
        sessions = await self.repo.bulk_create_sessions(str(plan.id), user_id, sessions_data)
        return plan, sessions

    async def get_plan(self, plan_id: str, user_id: str):
        plan = await self.repo.get_owned(plan_id, user_id)
        if not plan:
            raise NotFoundError("We couldn't find this study plan.")
        return plan

    async def get_sessions(self, plan_id: str, user_id: str):
        await self.get_plan(plan_id, user_id)  # ownership check
        return await self.repo.list_sessions_for_plan(plan_id)

    async def reschedule(self, plan_id: str, user_id: str) -> int:
        """Section 34/48: the simple version of 'recalculate when the
        student falls behind' — pushes every pending/missed session to
        start today, preserving their original relative order. Smarter
        rebalancing (prioritizing weak topics) needs quiz/performance
        data that doesn't exist until Phase 11-13."""
        await self.get_plan(plan_id, user_id)  # ownership check
        sessions = await self.repo.list_sessions_for_plan(plan_id)
        pending = sorted(
            (s for s in sessions if s.status in ("pending", "missed")),
            key=lambda s: s.scheduled_at,
        )
        today_slot = _session_datetime(date.today())
        updates = [(s, today_slot + timedelta(days=i)) for i, s in enumerate(pending)]
        await self.repo.apply_reschedule(updates)
        return len(updates)
