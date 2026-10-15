"""Unit tests for notification business rules."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest

from app.services.notification.rules import (
    ALL_RULES,
    NotificationIntent,
    evaluate_rules,
    rule_exam_countdown,
    rule_plan_nudge,
    rule_streak_alert,
    rule_study_reminder,
    rule_subscription_expiring,
)

# ---------------------------------------------------------------------------
# Fixtures / stubs
# ---------------------------------------------------------------------------

NOW = datetime(2026, 10, 15, 18, 0, tzinfo=timezone.utc)  # 18h UTC = 19h local


@dataclass
class StubUser:
    id: str = "user-1"
    full_name: str = "Alice Dupont"


@dataclass
class StubSession:
    id: str = "sess-1"
    subject_name: str = "Mathématiques"
    scheduled_at: datetime = NOW + timedelta(minutes=10)


@dataclass
class StubExam:
    id: str = "exam-1"
    name: str = "GCE A-Level Maths"
    exam_date: datetime = NOW + timedelta(days=7)


@dataclass
class StubPlan:
    id: str = "plan-1"
    name: str = "Révision Bac"
    status: str = "active"
    created_at: datetime = NOW - timedelta(days=10)


@dataclass
class StubSubscription:
    id: str = "sub-1"
    status: str = "active"
    current_period_end: datetime = NOW + timedelta(days=7)


# ---------------------------------------------------------------------------
# rule_study_reminder
# ---------------------------------------------------------------------------


class TestStudyReminder:
    def test_fires_within_window(self):
        intent = rule_study_reminder(
            now=NOW, user=StubUser(), upcoming_sessions=[StubSession()]
        )
        assert isinstance(intent, NotificationIntent)
        assert intent.template_key == "study_reminder"
        assert intent.context["user_name"] == "Alice"
        assert intent.context["subject_name"] == "Mathématiques"
        assert 1 <= intent.context["minutes"] <= 15
        assert intent.priority == 1
        assert intent.dedup_key == "study_reminder:sess-1"

    def test_no_fire_outside_window(self):
        s = StubSession(scheduled_at=NOW + timedelta(minutes=60))
        assert rule_study_reminder(now=NOW, user=StubUser(), upcoming_sessions=[s]) is None

    def test_no_fire_past_session(self):
        s = StubSession(scheduled_at=NOW - timedelta(minutes=5))
        assert rule_study_reminder(now=NOW, user=StubUser(), upcoming_sessions=[s]) is None

    def test_no_sessions(self):
        assert rule_study_reminder(now=NOW, user=StubUser(), upcoming_sessions=[]) is None

    def test_picks_soonest(self):
        s1 = StubSession(id="s1", subject_name="A", scheduled_at=NOW + timedelta(minutes=12))
        s2 = StubSession(id="s2", subject_name="B", scheduled_at=NOW + timedelta(minutes=3))
        intent = rule_study_reminder(now=NOW, user=StubUser(), upcoming_sessions=[s1, s2])
        assert intent is not None
        assert intent.context["subject_name"] == "B"
        assert intent.dedup_key == "study_reminder:s2"


# ---------------------------------------------------------------------------
# rule_streak_alert
# ---------------------------------------------------------------------------


class TestStreakAlert:
    def test_fires_after_20h_local_no_session(self):
        # NOW = 18h UTC = 19h local → too early
        assert (
            rule_streak_alert(
                now=NOW, user=StubUser(), streak_days=5, sessions_completed_today=0
            )
            is None
        )
        # 19h30 UTC = 20h30 local → fires
        late = datetime(2026, 10, 15, 19, 30, tzinfo=timezone.utc)
        intent = rule_streak_alert(
            now=late, user=StubUser(), streak_days=5, sessions_completed_today=0
        )
        assert intent is not None
        assert intent.context["streak_days"] == 5
        assert "2026-10-15" in intent.dedup_key

    def test_no_fire_if_session_today(self):
        late = datetime(2026, 10, 15, 20, 0, tzinfo=timezone.utc)
        assert (
            rule_streak_alert(
                now=late, user=StubUser(), streak_days=5, sessions_completed_today=2
            )
            is None
        )

    def test_no_fire_if_no_streak(self):
        late = datetime(2026, 10, 15, 20, 0, tzinfo=timezone.utc)
        assert (
            rule_streak_alert(
                now=late, user=StubUser(), streak_days=0, sessions_completed_today=0
            )
            is None
        )


# ---------------------------------------------------------------------------
# rule_exam_countdown
# ---------------------------------------------------------------------------


class TestExamCountdown:
    @pytest.mark.parametrize("days", [7, 3, 1])
    def test_fires_at_thresholds(self, days):
        exam = StubExam(exam_date=NOW + timedelta(days=days))
        intent = rule_exam_countdown(now=NOW, user=StubUser(), exam=exam)
        assert intent is not None
        assert intent.context["days_left"] == days
        assert f"J-{days}" in intent.dedup_key

    @pytest.mark.parametrize("days", [8, 6, 4, 2, 0])
    def test_no_fire_other_days(self, days):
        exam = StubExam(exam_date=NOW + timedelta(days=days))
        assert rule_exam_countdown(now=NOW, user=StubUser(), exam=exam) is None

    def test_no_exam(self):
        assert rule_exam_countdown(now=NOW, user=StubUser(), exam=None) is None


# ---------------------------------------------------------------------------
# rule_plan_nudge
# ---------------------------------------------------------------------------


class TestPlanNudge:
    def test_fires_after_inactivity(self):
        last = NOW - timedelta(days=5)
        intent = rule_plan_nudge(
            now=NOW, user=StubUser(), plan=StubPlan(), last_activity_at=last
        )
        assert intent is not None
        assert intent.context["plan_name"] == "Révision Bac"
        assert "W" in intent.dedup_key  # ISO week dedup

    def test_no_fire_recent_activity(self):
        last = NOW - timedelta(days=1)
        assert (
            rule_plan_nudge(
                now=NOW, user=StubUser(), plan=StubPlan(), last_activity_at=last
            )
            is None
        )

    def test_no_fire_inactive_plan(self):
        plan = StubPlan(status="completed")
        last = NOW - timedelta(days=10)
        assert (
            rule_plan_nudge(
                now=NOW, user=StubUser(), plan=plan, last_activity_at=last
            )
            is None
        )

    def test_uses_created_at_if_never_active(self):
        plan = StubPlan(created_at=NOW - timedelta(days=5))
        intent = rule_plan_nudge(
            now=NOW, user=StubUser(), plan=plan, last_activity_at=None
        )
        assert intent is not None


# ---------------------------------------------------------------------------
# rule_subscription_expiring
# ---------------------------------------------------------------------------


class TestSubscriptionExpiring:
    @pytest.mark.parametrize("days", [7, 1])
    def test_fires_at_thresholds(self, days):
        sub = StubSubscription(current_period_end=NOW + timedelta(days=days))
        intent = rule_subscription_expiring(now=NOW, user=StubUser(), subscription=sub)
        assert intent is not None
        assert intent.context["days_until_expiry"] == days

    def test_no_fire_other_days(self):
        sub = StubSubscription(current_period_end=NOW + timedelta(days=5))
        assert rule_subscription_expiring(now=NOW, user=StubUser(), subscription=sub) is None

    def test_no_fire_cancelled(self):
        sub = StubSubscription(
            status="cancelled", current_period_end=NOW + timedelta(days=1)
        )
        assert rule_subscription_expiring(now=NOW, user=StubUser(), subscription=sub) is None

    def test_no_subscription(self):
        assert rule_subscription_expiring(now=NOW, user=StubUser(), subscription=None) is None


# ---------------------------------------------------------------------------
# evaluate_rules
# ---------------------------------------------------------------------------


class TestEvaluateRules:
    def test_runs_multiple_rules_filters_kwargs(self):
        intent_study = rule_study_reminder(
            now=NOW, user=StubUser(), upcoming_sessions=[StubSession()]
        )
        # Build a full kwargs dict for all rules
        results = evaluate_rules(
            ALL_RULES,
            now=NOW,
            user=StubUser(),
            upcoming_sessions=[StubSession()],
            streak_days=5,
            sessions_completed_today=0,
            exam=StubExam(exam_date=NOW + timedelta(days=7)),
            plan=StubPlan(),
            last_activity_at=NOW - timedelta(days=5),
            subscription=StubSubscription(),
        )
        keys = {i.template_key for i in results}
        # study_reminder + exam_countdown + plan_nudge should fire
        assert "study_reminder" in keys
        assert "exam_countdown" in keys
        assert "plan_nudge" in keys
        # streak_alert should NOT fire (before 20h local)
        assert "streak_alert" not in keys

    def test_returns_empty_when_nothing_fires(self):
        results = evaluate_rules(
            ALL_RULES,
            now=NOW,
            user=StubUser(),
            upcoming_sessions=[],
            streak_days=0,
            sessions_completed_today=1,
            exam=None,
            plan=None,
            subscription=None,
        )
        assert results == []