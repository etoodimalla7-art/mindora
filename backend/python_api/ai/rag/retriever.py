"""Semantic search over indexed document chunks."""
from __future__ import annotations

import logging
import uuid
from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.ai.factory import get_embedding_provider
from app.models.document import DOC_STATUS_APPROVED, Document
from app.models.document_chunk import DocumentChunk

logger = logging.getLogger(__name__)

# Number of results to return.
DEFAULT_TOP_K = 5


@dataclass
class RetrievedChunk:
    chunk_id: uuid.UUID
    document_id: uuid.UUID
    document_title: str
    chunk_index: int
    content: str
    similarity: float  # 0..1 (higher is closer)


async def search_documents(
    session: AsyncSession,
    *,
    query: str,
    user_id: uuid.UUID,
    top_k: int = DEFAULT_TOP_K,
    document_id: uuid.UUID | None = None,
) -> list[RetrievedChunk]:
    """Find the most relevant chunks for a query.

    Phase 8B scope: only search in the user's own approved documents.
    Phase 9+ will extend to the global approved corpus.
    """
    if not query.strip():
        return []

    provider = get_embedding_provider()
    try:
        result = await provider.embed([query])
    except Exception as exc:  # noqa: BLE001
        logger.error("query_embed_failed error=%s", exc)
        return []

    if not result.vectors:
        return []
    query_vec = result.vectors[0]

    # pgvector cosine distance operator: `<=>`
    # Lower distance = more similar. Convert to similarity = 1 - distance.
    stmt = (
        select(
            DocumentChunk.id,
            DocumentChunk.document_id,
            DocumentChunk.chunk_index,
            DocumentChunk.content,
            Document.title,
            DocumentChunk.embedding.cosine_distance(query_vec).label("distance"),
        )
        .join(Document, Document.id == DocumentChunk.document_id)
        .where(
            Document.owner_id == user_id,
            Document.status == DOC_STATUS_APPROVED,
            Document.deleted_at.is_(None),
        )
    )
    if document_id is not None:
        stmt = stmt.where(DocumentChunk.document_id == document_id)

    stmt = stmt.order_by("distance").limit(top_k)

    rows = (await session.execute(stmt)).all()
    return [
        RetrievedChunk(
            chunk_id=r.id,
            document_id=r.document_id,
            document_title=r.title,
            chunk_index=r.chunk_index,
            content=r.content,
            similarity=max(0.0, 1.0 - float(r.distance)),
        )
        for r in rows
    ]
