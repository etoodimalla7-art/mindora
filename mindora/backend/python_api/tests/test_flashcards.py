"""Tests for SM-2 spaced repetition algorithm and Flashcards REST API (B1)."""
from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone

import pytest

from app.services.sm2 import update_sm2


def _email() -> str:
    return f"flash_{uuid.uuid4().hex[:8]}@mindora.dev"


def test_sm2_formula_schedule_progression_and_reset() -> None:
    now = datetime(2026, 11, 19, 12, 0, tzinfo=timezone.utc)

    # Review 1: quality 5 -> rep=1, interval=1 day, EF'=2.5 + 0.1 = 2.6
    r1 = update_sm2(
        current_ease=2.5,
        current_interval=1,
        current_repetitions=0,
        quality=5,
        now=now,
    )
    assert r1.repetitions == 1
    assert r1.interval_days == 1
    assert r1.ease_factor == pytest.approx(2.6, abs=1e-2)
    assert r1.next_review_at == now + timedelta(days=1)

    # Review 2: quality 4 -> rep=2, interval=6 days, EF'=2.6 + (0.1 - 0.1) = 2.6
    r2 = update_sm2(
        current_ease=r1.ease_factor,
        current_interval=r1.interval_days,
        current_repetitions=r1.repetitions,
        quality=4,
        now=now,
    )
    assert r2.repetitions == 2
    assert r2.interval_days == 6
    assert r2.ease_factor == pytest.approx(2.6, abs=1e-2)
    assert r2.next_review_at == now + timedelta(days=6)

    # Review 3: quality 4 -> rep=3, interval=round(6 * 2.6) = 16 days
    r3 = update_sm2(
        current_ease=r2.ease_factor,
        current_interval=r2.interval_days,
        current_repetitions=r2.repetitions,
        quality=4,
        now=now,
    )
    assert r3.repetitions == 3
    assert r3.interval_days == round(6 * r2.ease_factor)
    assert r3.next_review_at == now + timedelta(days=r3.interval_days)

    # Failure (quality < 3): resets repetitions=0, interval=1, EF floored at 1.3
    r_fail = update_sm2(
        current_ease=1.35,
        current_interval=r3.interval_days,
        current_repetitions=r3.repetitions,
        quality=0,
        now=now,
    )
    assert r_fail.repetitions == 0
    assert r_fail.interval_days == 1
    assert r_fail.ease_factor == 1.3

    with pytest.raises(ValueError):
        update_sm2(
            current_ease=2.5,
            current_interval=1,
            current_repetitions=0,
            quality=6,
            now=now,
        )


@pytest.mark.asyncio
async def test_flashcards_crud_due_and_review_flow(client) -> None:
    r = await client.post(
        "/api/v1/auth/register",
        json={
            "email": _email(),
            "password": "FlashPass123!",
            "full_name": "SM2 Student",
            "preferred_language": "fr",
            "country_code": "CM",
        },
    )
    assert r.status_code == 201, r.text
    headers = {"Authorization": f"Bearer {r.json()['tokens']['access_token']}"}

    # 1. Create deck
    r = await client.post(
        "/api/v1/flashcards/decks",
        headers=headers,
        json={
            "title": "Bac C — Nombres complexes",
            "description": "Forme trigonométrique et module",
            "subject": "Mathematics",
        },
    )
    assert r.status_code == 201, r.text
    deck = r.json()
    deck_id = deck["id"]
    assert deck["card_count"] == 0

    # 2. List decks
    r = await client.get("/api/v1/flashcards/decks", headers=headers)
    assert r.status_code == 200, r.text
    assert any(d["id"] == deck_id for d in r.json())

    # 3. Add two cards
    c1 = await client.post(
        f"/api/v1/flashcards/decks/{deck_id}/cards",
        headers=headers,
        json={"front": "|e^(iθ)| = ?", "back": "1"},
    )
    assert c1.status_code == 201, c1.text
    card1_id = c1.json()["id"]

    c2 = await client.post(
        f"/api/v1/flashcards/decks/{deck_id}/cards",
        headers=headers,
        json={"front": "Formule de Moivre ?", "back": "(cos θ + i sin θ)^n = cos(nθ) + i sin(nθ)"},
    )
    assert c2.status_code == 201, c2.text
    card2_id = c2.json()["id"]

    # 4. Due cards (global & per-deck)
    r_due_all = await client.get("/api/v1/flashcards/due", headers=headers)
    assert r_due_all.status_code == 200, r_due_all.text
    due_ids = {c["id"] for c in r_due_all.json()}
    assert {card1_id, card2_id}.issubset(due_ids)

    r_due_deck = await client.get(
        f"/api/v1/flashcards/decks/{deck_id}/cards/due", headers=headers
    )
    assert r_due_deck.status_code == 200, r_due_deck.text
    assert len(r_due_deck.json()) == 2

    # 5. Review card1 progression: q=5 -> q=4 -> q=1 (reset)
    rev1 = await client.post(
        f"/api/v1/flashcards/cards/{card1_id}/review",
        headers=headers,
        json={"quality": 5},
    )
    assert rev1.status_code == 200, rev1.text
    d1 = rev1.json()
    assert d1["repetitions"] == 1
    assert d1["interval_days"] == 1
    assert d1["last_quality"] == 5
    assert d1["review_count"] == 1

    # Card1 should no longer appear in due queue
    r_due_after = await client.get(
        f"/api/v1/flashcards/decks/{deck_id}/cards/due", headers=headers
    )
    assert r_due_after.status_code == 200
    assert [c["id"] for c in r_due_after.json()] == [card2_id]

    rev2 = await client.post(
        f"/api/v1/flashcards/cards/{card1_id}/review",
        headers=headers,
        json={"quality": 4},
    )
    assert rev2.status_code == 200
    d2 = rev2.json()
    assert d2["repetitions"] == 2
    assert d2["interval_days"] == 6
    assert d2["review_count"] == 2

    rev3 = await client.post(
        f"/api/v1/flashcards/cards/{card1_id}/review",
        headers=headers,
        json={"quality": 1},
    )
    assert rev3.status_code == 200
    d3 = rev3.json()
    assert d3["repetitions"] == 0
    assert d3["interval_days"] == 1
    assert d3["last_quality"] == 1
    assert d3["review_count"] == 3
