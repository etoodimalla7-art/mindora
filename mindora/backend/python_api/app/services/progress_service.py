"""Student progress service — server-side streaks, heatmaps & study recommendations."""
from __future__ import annotations

import uuid
from collections import defaultdict
from datetime import date, datetime, timedelta, timezone
from typing import Any

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.flashcard import Flashcard, FlashcardDeck
from app.models.mock_exam import MOCK_STATUS_GRADED, MockExam
from app.models.plan import StudySession
from app.models.progress import TopicProgress, UserProgress
from app.services.dashboard_service import DashboardService


def _compute_streaks(active_dates: set[date], today: date) -> tuple[int, int]:
    """Compute (current_streak, longest_streak) from a set of active UTC dates."""
    if not active_dates:
        return 0, 0

    sorted_days = sorted(active_dates)
    longest = 1
    run = 1
    for i in range(1, len(sorted_days)):
        if (sorted_days[i] - sorted_days[i - 1]).days == 1:
            run += 1
            if run > longest:
                longest = run
        else:
            run = 1

    # Current streak: starts from today, or yesterday if student hasn't studied today yet
    cursor = today if today in active_dates else (today - timedelta(days=1))
    current = 0
    while cursor in active_dates:
        current += 1
        cursor -= timedelta(days=1)

    return current, max(longest, current)


class ProgressService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def _collect_daily_activity(
        self, user_id: uuid.UUID
    ) -> tuple[dict[date, dict[str, int]], int, int, int, int]:
        daily: dict[date, dict[str, int]] = defaultdict(
            lambda: {"minutes": 0, "sessions": 0, "flashcards": 0, "exams": 0}
        )

        # 1. Completed study sessions
        sess_rows = (
            await self.session.execute(
                select(
                    StudySession.completed_at,
                    StudySession.scheduled_for,
                    StudySession.duration_minutes,
                ).where(
                    StudySession.user_id == user_id,
                    StudySession.status == "completed",
                )
            )
        ).all()
        total_sessions = len(sess_rows)
        total_minutes = 0
        for comp_at, sched_at, mins in sess_rows:
            ts = comp_at or sched_at
            m = int(mins or 0)
            total_minutes += m
            if ts is not None:
                d = ts.astimezone(timezone.utc).date() if ts.tzinfo else ts.date()
                daily[d]["sessions"] += 1
                daily[d]["minutes"] += m

        # 2. Flashcard reviews
        fc_rows = (
            await self.session.execute(
                select(Flashcard.last_reviewed_at, Flashcard.review_count)
                .join(FlashcardDeck, Flashcard.deck_id == FlashcardDeck.id)
                .where(
                    FlashcardDeck.user_id == user_id,
                    Flashcard.last_reviewed_at.isnot(None),
                )
            )
        ).all()
        total_flashcards = 0
        for rev_at, rev_count in fc_rows:
            total_flashcards += max(1, int(rev_count or 0))
            if rev_at is not None:
                d = rev_at.astimezone(timezone.utc).date() if rev_at.tzinfo else rev_at.date()
                daily[d]["flashcards"] += 1
                daily[d]["minutes"] += 2

        # 3. Graded mock exams
        exam_rows = (
            await self.session.execute(
                select(MockExam.submitted_at, MockExam.created_at).where(
                    MockExam.user_id == user_id,
                    MockExam.status == MOCK_STATUS_GRADED,
                )
            )
        ).all()
        total_exams = len(exam_rows)
        for sub_at, cr_at in exam_rows:
            ts = sub_at or cr_at
            if ts is not None:
                d = ts.astimezone(timezone.utc).date() if ts.tzinfo else ts.date()
                daily[d]["exams"] += 1
                daily[d]["minutes"] += 30

        # Also factor topic_progress minutes if higher
        topic_mins = int(
            (
                await self.session.execute(
                    select(func.coalesce(func.sum(TopicProgress.minutes_studied), 0)).where(
                        TopicProgress.user_id == user_id
                    )
                )
            ).scalar_one()
            or 0
        )
        total_minutes = max(total_minutes, topic_mins)

        return daily, total_minutes, total_sessions, total_flashcards, total_exams

    async def sync_user_progress(self, user_id: uuid.UUID) -> UserProgress:
        daily, total_minutes, total_sessions, total_flashcards, total_exams = (
            await self._collect_daily_activity(user_id)
        )
        today = datetime.now(timezone.utc).date()
        current_streak, longest_streak = _compute_streaks(set(daily.keys()), today)
        last_activity = max(daily.keys()) if daily else None
        total_xp = total_sessions * 25 + total_flashcards * 5 + total_exams * 50

        row = (
            await self.session.execute(
                select(UserProgress).where(UserProgress.user_id == user_id)
            )
        ).scalar_one_or_none()
        if row is None:
            row = UserProgress(user_id=user_id)
            self.session.add(row)

        row.current_streak = current_streak
        row.longest_streak = max(row.longest_streak or 0, longest_streak)
        row.total_xp = total_xp
        row.total_minutes = total_minutes
        row.sessions_completed = total_sessions
        row.flashcards_reviewed = total_flashcards
        row.exams_completed = total_exams
        row.last_activity_date = last_activity
        await self.session.commit()
        await self.session.refresh(row)
        return row

    async def get_my_progress(self, user_id: uuid.UUID) -> dict[str, Any]:
        prog = await self.sync_user_progress(user_id)
        dash = await DashboardService(self.session).build(user_id)
        topics_rows = (
            await self.session.execute(
                select(TopicProgress)
                .where(TopicProgress.user_id == user_id)
                .order_by(TopicProgress.mastery.asc(), TopicProgress.updated_at.desc())
            )
        ).scalars().all()

        return {
            "user_id": user_id,
            "current_streak": prog.current_streak,
            "longest_streak": prog.longest_streak,
            "total_xp": prog.total_xp,
            "total_minutes": prog.total_minutes,
            "sessions_completed": prog.sessions_completed,
            "flashcards_reviewed": prog.flashcards_reviewed,
            "exams_completed": prog.exams_completed,
            "last_activity_date": prog.last_activity_date,
            "readiness_score": dash.readiness_score,
            "readiness_breakdown": dash.readiness_breakdown,
            "weak_topics": dash.weak_topics,
            "topics": topics_rows,
        }

    async def get_history(self, user_id: uuid.UUID, days: int = 30) -> dict[str, Any]:
        daily, _, _, _, _ = await self._collect_daily_activity(user_id)
        today = datetime.now(timezone.utc).date()
        current_streak, longest_streak = _compute_streaks(set(daily.keys()), today)

        start = today - timedelta(days=days - 1)
        heatmap: list[dict[str, Any]] = []
        active_days = 0
        for offset in range(days):
            d = start + timedelta(days=offset)
            bucket = daily.get(d, {"minutes": 0, "sessions": 0, "flashcards": 0, "exams": 0})
            mins = bucket["minutes"]
            total_events = bucket["sessions"] + bucket["flashcards"] + bucket["exams"]
            if total_events > 0 or mins > 0:
                active_days += 1
            if mins == 0 and total_events == 0:
                level = 0
            elif mins < 20:
                level = 1
            elif mins < 45:
                level = 2
            elif mins < 90:
                level = 3
            else:
                level = 4

            heatmap.append(
                {
                    "date": d.isoformat(),
                    "minutes": mins,
                    "sessions": bucket["sessions"],
                    "flashcards": bucket["flashcards"],
                    "exams": bucket["exams"],
                    "activity_level": level,
                }
            )

        return {
            "days": days,
            "current_streak": current_streak,
            "longest_streak": longest_streak,
            "active_days": active_days,
            "heatmap": heatmap,
        }

    async def get_recommendation(self, user_id: uuid.UUID) -> dict[str, Any]:
        # 1. Check weak topic (mastery < 0.7)
        weak = (
            await self.session.execute(
                select(TopicProgress)
                .where(TopicProgress.user_id == user_id)
                .order_by(TopicProgress.mastery.asc(), TopicProgress.questions_seen.asc())
                .limit(1)
            )
        ).scalar_one_or_none()
        if weak is not None and weak.mastery < 0.7:
            pct = int(round(weak.mastery * 100))
            return {
                "action_type": "review_weak_topic",
                "subject": weak.subject,
                "topic": weak.topic,
                "title": f"Renforcer : {weak.topic} ({weak.subject})",
                "reason": f"Ta maîtrise actuelle sur ce chapitre est de {pct} %. Une séance ciblée augmentera rapidement ton score de préparation.",
                "estimated_minutes": 30,
                "deep_link": "/tutor",
            }

        # 2. Check due SM-2 flashcards
        now = datetime.now(timezone.utc)
        due_count = int(
            (
                await self.session.execute(
                    select(func.count(Flashcard.id))
                    .join(FlashcardDeck, Flashcard.deck_id == FlashcardDeck.id)
                    .where(
                        FlashcardDeck.user_id == user_id,
                        or_(
                            Flashcard.next_review_at.is_(None),
                            Flashcard.next_review_at <= now,
                        ),
                    )
                )
            ).scalar_one()
            or 0
        )
        if due_count > 0:
            return {
                "action_type": "review_flashcards",
                "subject": "Révision SM-2",
                "topic": f"{due_count} carte(s) à réviser",
                "title": f"Réviser {due_count} flashcard(s) dues aujourd'hui",
                "reason": "La répétition espacée SM-2 ancre durablement les formules et définitions avant qu'elles ne s'effacent.",
                "estimated_minutes": min(25, max(5, due_count * 2)),
                "deep_link": "/learn/flashcards",
            }

        # 3. Default mock exam recommendation
        return {
            "action_type": "take_mock_exam",
            "subject": "Simulation d'examen",
            "topic": "Examen blanc chronométré",
            "title": "Lancer un examen blanc pour tester ta vitesse",
            "reason": "Tu es à jour sur tes révisions : un examen blanc mesure ta préparation réelle en conditions officielles.",
            "estimated_minutes": 45,
            "deep_link": "/learn/mock-exams",
        }
