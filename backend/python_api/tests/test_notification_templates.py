"""Unit tests for notification templates."""

import pytest

from app.services.notification.templates import (
    DEFAULT_LOCALE,
    TEMPLATES,
    NotificationContent,
    get_template_raw,
    list_templates,
    render,
)


class TestRender:
    def test_render_fr_full_context(self):
        content = render(
            "session_reminder",
            "fr",
            {"user_name": "Alice", "subject_name": "Mathématiques", "minutes": 15},
        )
        assert isinstance(content, NotificationContent)
        assert content.title == "📚 C'est l'heure, Alice !"
        assert content.body == "Ta session Mathématiques commence dans 15 min."

    def test_render_en_full_context(self):
        content = render(
            "session_reminder",
            "en",
            {"user_name": "Bob", "subject_name": "Physics", "minutes": 30},
        )
        assert content.title == "📚 Time to study, Bob!"
        assert content.body == "Your Physics session starts in 30 min."

    def test_render_streak_fr(self):
        content = render("streak", "fr", {"user_name": "Alice", "streak_days": 7})
        assert "7" in content.title
        assert "Alice" not in content.body  # body uses no name

    def test_render_exam_countdown_en(self):
        content = render(
            "exam_countdown",
            "en",
            {"user_name": "Bob", "days_left": 3, "subject_name": "Maths"},
        )
        assert "3" in content.title

    def test_render_inactivity_fr(self):
        content = render(
            "inactivity",
            "fr",
            {"user_name": "Alice", "plan_name": "Bac 2026"},
        )
        assert "Bac 2026" in content.body

    def test_render_subscription_expiring(self):
        content = render(
            "subscription_expiring",
            "fr",
            {"user_name": "Alice", "days_until_expiry": 7},
        )
        assert "7" in content.title

    def test_render_unknown_locale_falls_back_to_default(self):
        content = render(
            "session_reminder",
            "de",
            {"user_name": "Alice", "subject_name": "Bio", "minutes": 5},
        )
        assert "Alice" in content.title

    def test_render_none_locale_uses_default(self):
        content = render(
            "session_reminder",
            None,
            {"user_name": "Alice", "subject_name": "Bio", "minutes": 5},
        )
        assert "Alice" in content.title

    def test_missing_variable_placeholder(self):
        content = render("session_reminder", "fr", {"user_name": "Alice"})
        assert "[subject_name]" in content.body
        assert "[minutes]" in content.body

    def test_none_value_treated_as_missing(self):
        content = render(
            "session_reminder",
            "fr",
            {"user_name": None, "subject_name": "Bio", "minutes": 5},
        )
        assert "[user_name]" in content.title

    def test_unknown_template_raises(self):
        with pytest.raises(KeyError):
            render("does_not_exist", "fr", {})

    def test_locale_with_region_code(self):
        content = render(
            "session_reminder",
            "fr-FR",
            {"user_name": "Alice", "subject_name": "Bio", "minutes": 5},
        )
        assert "Alice" in content.title

    def test_system_fallback(self):
        content = render("system", "fr", {"title": "Hello", "body": "World"})
        assert content.title == "Hello"
        assert content.body == "World"


class TestRegistry:
    def test_all_templates_have_fr_and_en(self):
        for key, variants in TEMPLATES.items():
            assert "fr" in variants, f"{key} missing FR"
            assert "en" in variants, f"{key} missing EN"
            for loc, tpl in variants.items():
                assert tpl.get("title"), f"{key}/{loc} title empty"
                assert tpl.get("body"), f"{key}/{loc} body empty"

    def test_list_templates_sorted(self):
        keys = list_templates()
        assert keys == sorted(keys)
        assert "session_reminder" in keys
        assert "streak" in keys
        assert "inactivity" in keys
        assert len(keys) >= 9

    def test_get_template_raw_unknown_raises(self):
        with pytest.raises(KeyError):
            get_template_raw("nope", "fr")

    def test_get_template_raw_returns_copy(self):
        tpl = get_template_raw("session_reminder", "fr")
        tpl["title"] = "MUTATED"
        assert TEMPLATES["session_reminder"]["fr"]["title"] != "MUTATED"
