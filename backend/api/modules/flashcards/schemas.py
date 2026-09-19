from pydantic import BaseModel, Field


class GenerateFlashcardsIn(BaseModel):
    topic_title: str = Field(min_length=1)
    source_document_id: str | None = None
    max_cards: int = Field(default=10, ge=1, le=30)


class FlashcardOut(BaseModel):
    id: str
    topic_title: str
    front: str
    back: str
    card_type: str

    class Config:
        from_attributes = True


class ReviewFlashcardIn(BaseModel):
    state: str = Field(pattern="^(known|uncertain|forgotten)$")
