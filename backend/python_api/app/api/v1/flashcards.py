"""Flashcards API endpoints."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query, Response, status

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.flashcard import (
    DeckCreate,
    DeckOut,
    FlashcardCreate,
    FlashcardOut,
    ReviewCardRequest,
    ReviewCardResponse,
)
from app.services.flashcard_service import FlashcardService

router = APIRouter()


@router.get("/decks", response_model=list[DeckOut])
async def list_decks(
    session: SessionDep, user_id: CurrentUserId
) -> list[DeckOut]:
    return await FlashcardService(session).list_decks(user_id)


@router.post("/decks", response_model=DeckOut, status_code=status.HTTP_201_CREATED)
async def create_deck(
    payload: DeckCreate, session: SessionDep, user_id: CurrentUserId
) -> DeckOut:
    return await FlashcardService(session).create_deck(
        user_id, payload.title, payload.description, payload.subject
    )


@router.delete("/decks/{deck_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_deck(
    deck_id: uuid.UUID, session: SessionDep, user_id: CurrentUserId
) -> Response:
    await FlashcardService(session).delete_deck(user_id, deck_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/decks/{deck_id}/cards",
    response_model=FlashcardOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_card(
    deck_id: uuid.UUID,
    payload: FlashcardCreate,
    session: SessionDep,
    user_id: CurrentUserId,
) -> FlashcardOut:
    return await FlashcardService(session).add_card(
        user_id, deck_id, payload.front, payload.back
    )


@router.get("/decks/{deck_id}/cards/due", response_model=list[FlashcardOut])
async def get_due_cards(
    deck_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
    limit: int = Query(default=20, ge=1, le=100),
) -> list[FlashcardOut]:
    return await FlashcardService(session).get_due_cards(user_id, deck_id, limit)


@router.post("/cards/{card_id}/review", response_model=ReviewCardResponse)
async def review_card(
    card_id: uuid.UUID,
    payload: ReviewCardRequest,
    session: SessionDep,
    user_id: CurrentUserId,
) -> ReviewCardResponse:
    return await FlashcardService(session).review_card(
        user_id, card_id, payload.quality
    )
