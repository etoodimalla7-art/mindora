"""Document schemas — request and response DTOs."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class DocumentAnalysisOut(BaseModel):
    detected_language: str | None = None
    language_confidence: float = 0.0
    detected_subject: str | None = None
    subject_confidence: float = 0.0
    detected_level: str | None = None
    level_confidence: float = 0.0
    detected_doc_type: str | None = None
    doc_type_confidence: float = 0.0
    is_spam: bool = False
    is_inappropriate: bool = False
    contains_pii: bool = False
    quality_score: float = 0.0
    keywords: list[str] = Field(default_factory=list)
    summary: str | None = None

    class Config:
        from_attributes = True


class DocumentDuplicateOut(BaseModel):
    candidate_id: uuid.UUID
    similarity: float
    matched_on: str
    reviewed: bool
    verdict: str | None = None

    class Config:
        from_attributes = True


class DocumentOut(BaseModel):
    id: uuid.UUID
    owner_id: uuid.UUID
    title: str
    description: str
    category: str | None = None
    academic_level: str | None = None
    language: str
    is_exam_related: bool
    exam_system: str | None = None
    exam_name: str | None = None
    exam_year: int | None = None
    exam_session: str | None = None
    document_type: str | None = None
    original_filename: str
    mime_type: str
    size_bytes: int
    page_count: int | None = None
    status: str
    rejection_reason: str | None = None
    download_count: int
    quality_score: float
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class DocumentDetail(DocumentOut):
    analysis: DocumentAnalysisOut | None = None
    duplicates: list[DocumentDuplicateOut] = Field(default_factory=list)


class DocumentStatusOut(BaseModel):
    """Lightweight status payload used by the upload progress screen."""

    id: uuid.UUID
    status: str
    steps: dict[str, str] = Field(default_factory=dict)
    rejection_reason: str | None = None


class SubmitDocumentRequest(BaseModel):
    """Triggered by the client once the description is written and the file
    is uploaded. Fields are merged into the existing document row."""

    category: str | None = Field(default=None, max_length=80)
    academic_level: str | None = Field(default=None, max_length=40)
    language: str | None = Field(default=None, max_length=8)
    is_exam_related: bool = False
    exam_system: str | None = Field(default=None, max_length=40)
    exam_name: str | None = Field(default=None, max_length=120)
    exam_year: int | None = Field(default=None, ge=1900, le=2100)
    exam_session: str | None = Field(default=None, max_length=40)
    document_type: str | None = Field(default=None, max_length=60)