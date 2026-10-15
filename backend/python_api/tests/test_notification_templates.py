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
            "study_reminder",
            "fr",
            {
                "user_name": "Alice",
                "subject_name": "Mathématiques",
                "minutes": 15,
            },
        )
        assert isinstance(content, NotificationContent)
        assert content.title == "📚 C'est l'heure, Alice !"
        assert content.body == "Ta session Mathématiques commence dans 15 min."

    def test_render_en_full_context(self):
        content = render(
            "study_reminder",
            "en",
            {
                "user_name": "Bob",
                "subject_name": "Physics",
                "minutes": 30,
            },
        )
        assert content.title == "📚 Time to study, Bob!"
        assert content.body == "Your Physics session starts in 30 min."

    def test_render_unknown_locale_falls_back_to_default(self):
        content = render(
            "study_reminder",
            "de",  # unsupported
            {"user_name": "Alice", "subject_name": "Bio", "minutes": 5},
        )
        # Should fallback to FR (DEFAULT_LOCALE)
        assert "Alice" in content.title
        assert "Bio" in content.body

    def test_render_none_locale_uses_default(self):
        content = render(
            "study_reminder",
            None,
            {"user_name": "Alice", "subject_name": "Bio", "minutes": 5},
        )
        assert "Alice" in content.title

    def test_missing_variable_placeholder(self):
        content = render("study_reminder", "fr", {"user_name": "Alice"})
        # subject_name and minutes are missing → placeholders
        assert "[subject_name]" in content.body
        assert "[minutes]" in content.body

    def test_none_value_treated_as_missing(self):
        content = render(
            "study_reminder",
            "fr",
            {"user_name": None, "subject_name": "Bio", "minutes": 5},
        )
        assert "[user_name]" in content.title

    def test_unknown_template_raises(self):
        with pytest.raises(KeyError):
            render("does_not_exist", "fr", {})

    def test_empty_context(self):
        content = render("streak_alert", "fr", {})
        assert "[streak_days]" in content.title

    def test_locale_with_region_code(self):
        # "fr-FR" should normalize to "fr"
        content = render(
            "study_reminder",
            "fr-FR",
            {"user_name": "Alice", "subject_name": "Bio", "minutes": 5},
        )
        assert "Alice" in content.title


class TestRegistry:
    def test_all_templates_have_fr_and_en(self):
        for key, variants in TEMPLATES.items():
            assert "fr" in variants, f"{key} missing FR"
            assert "en" in variants, f"{key} missing EN"
            for loc, tpl in variants.items():
                assert "title" in tpl and tpl["title"], f"{key}/{loc} title empty"
                assert "body" in tpl and tpl["body"], f"{key}/{loc} body empty"

    def test_list_templates_sorted(self):
        keys = list_templates()
        assert keys == sorted(keys)
        assert "study_reminder" in keys
        assert len(keys) >= 7

    def test_get_template_raw_unknown_raises(self):
        with pytest.raises(KeyError):
            get_template_raw("nope", "fr")

    def test_get_template_raw_returns_copy(self):
        tpl = get_template_raw("study_reminder", "fr")
        tpl["title"] = "MUTATED"
        # Original registry must not be mutated
        assert TEMPLATES["study_reminder"]["fr"]["title"] != "MUTATED"
