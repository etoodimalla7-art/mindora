"""
Pure functions across every module — no DB, no HTTP, no fixtures.
These run in milliseconds and are the first line of defense; the
heavier integration tests above exist for what these can't reach
(persistence, HTTP serialization, cross-module wiring).
"""
from datetime import datetime, timezone

from api.core.ids import to_uuid
from api.modules.credits.rules import can_download, credits_from_new_approvals
from api.modules.documents.validation import validate_description
from api.modules.flashcards.generation import extract_definition_pairs, generate_flashcards_from_text
from api.modules.flashcards.spaced_repetition import compute_next_due
from api.modules.mock_exams.scoring import score_sections
from api.modules.notifications.generation import is_within_quiet_hours
from api.modules.planner.generation import build_session_plan
from api.modules.progress.analytics import compute_readiness, compute_subject_mastery
from api.modules.quizzes.generation import generate_quiz_from_text


def test_to_uuid_accepts_string_and_uuid():
    import uuid
    u = uuid.uuid4()
    assert to_uuid(str(u)) == u
    assert to_uuid(u) == u


def test_description_validation_word_count():
    assert validate_description("too short")
    varied_long_text = " ".join(f"word{i % 50}" for i in range(600))  # >500 unique-ish words, no repetition flag
    assert not validate_description(varied_long_text)


def test_flashcard_pronoun_filter():
    text = "This is not a real definition. Photosynthesis is the process of converting light to energy."
    pairs = extract_definition_pairs(text)
    assert not any(term.lower() == "this" for term, _ in pairs)
    assert any("photosynthesis" in term.lower() for term, _ in pairs)


def test_quiz_answer_position_not_gameable():
    text = (
        "Mitosis is cell division producing two daughter cells. "
        "Osmosis is water movement across a membrane. "
        "Meiosis is cell division producing gametes. "
        "Diffusion is the movement of particles from high to low concentration."
    )
    quiz = generate_quiz_from_text(text, "Biology", num_questions=4)
    positions = [q["choices"].index(q["correct_answer"]) for q in quiz]
    assert len(set(positions)) > 1


def test_spaced_repetition_streak_and_reset():
    due1, streak1 = compute_next_due("known", 0)
    assert streak1 == 1
    due2, streak2 = compute_next_due("known", streak1)
    assert streak2 == 2
    _, streak_reset = compute_next_due("forgotten", streak2)
    assert streak_reset == 0


def test_planner_fallback_for_subject_with_no_topics():
    plan = build_session_plan({"Geography": []}, total_days=3)
    assert all(p["topic_title"] == "General review" for p in plan)


def test_credits_multi_threshold_crossing():
    assert credits_from_new_approvals(0, 10) == 10  # crosses TWO thresholds at once
    assert can_download(0, has_active_subscription=True)
    assert not can_download(0, has_active_subscription=False)


def test_mock_exam_scoring_weighted_not_averaged():
    overall, sections = score_sections({"Math": (5, 5), "Physics": (0, 5)})
    assert overall == 50.0
    assert sections == {"Math": 100.0, "Physics": 0.0}


def test_quiet_hours_midnight_wrap():
    at_11pm = datetime(2026, 1, 1, 23, 0, tzinfo=timezone.utc)
    at_noon = datetime(2026, 1, 1, 12, 0, tzinfo=timezone.utc)
    assert is_within_quiet_hours(at_11pm, 22, 7) is True
    assert is_within_quiet_hours(at_noon, 22, 7) is False


def test_readiness_zero_for_brand_new_student():
    result = compute_readiness(
        avg_quiz_score=None, quiz_attempt_count=0, flashcard_review_count=0,
        flashcard_known_ratio=None, avg_mock_exam_score=None, weak_subject_ratio=1.0, streak_days=0,
    )
    assert result["overall"] == 0.0


def test_subject_mastery_blend():
    assert compute_subject_mastery(None, None) == 0.0
    assert compute_subject_mastery(80.0, 1.0) == round(80 * 0.6 + 100 * 0.4, 1)
