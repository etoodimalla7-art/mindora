"""Document chunk model — stores text chunks with pgvector embeddings."""
from __future__ import annotations

import uuid

from pgvector.sqlalchemy import Vector
from sqlalchemy import ForeignKey, Integer, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDMixin

# Must match EMBEDDING_DIMENSIONS in app/integrations/ai/gemini.py
EMBEDDING_DIM = 768


class DocumentChunk(Base, UUIDMixin, TimestampMixin):
    """A chunk of text from a document, with its vector embedding."""

    __tablename__ = "document_chunks"

    document_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("documents.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )

    chunk_index: Mapped[int] = mapped_column(Integer, nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    token_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # 768-dim embedding (matches gemini-embedding-001 output_dim).
    embedding: Mapped[list[float]] = mapped_column(
        Vector(EMBEDDING_DIM), nullable=False
    )

    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
