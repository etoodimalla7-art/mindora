"""Index documents into the vector store."""
from __future__ import annotations

import logging
import uuid

from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.ai.factory import get_embedding_provider
from app.models.document import Document
from app.models.document_chunk import DocumentChunk
from ai.rag.chunker import chunk_text

logger = logging.getLogger(__name__)

# Batch size for embedding API calls.
BATCH_SIZE = 8


async def index_document(session: AsyncSession, doc: Document) -> int:
    """Chunk + embed a document and store the results.

    Removes any existing chunks for the document first, so this function
    is idempotent and can be re-run after a document is re-approved.
    """
    text = doc.extracted_text or ""
    if not text.strip():
        logger.info("index_document skipped (empty text) doc_id=%s", doc.id)
        return 0

    # Clear previous chunks.
    await session.execute(
        delete(DocumentChunk).where(DocumentChunk.document_id == doc.id)
    )

    chunks = chunk_text(text)
    if not chunks:
        return 0

    provider = get_embedding_provider()
    inserted = 0

    for start in range(0, len(chunks), BATCH_SIZE):
        batch = chunks[start : start + BATCH_SIZE]
        texts = [c.content for c in batch]
        try:
            result = await provider.embed(texts)
        except Exception as exc:  # noqa: BLE001
            logger.error("embed_batch_failed doc_id=%s error=%s", doc.id, exc)
            continue

        if len(result.vectors) != len(batch):
            logger.warning(
                "embed_count_mismatch doc_id=%s expected=%d got=%d",
                doc.id,
                len(batch),
                len(result.vectors),
            )
            continue

        for chunk, vec in zip(batch, result.vectors):
            session.add(
                DocumentChunk(
                    document_id=doc.id,
                    chunk_index=chunk.index,
                    content=chunk.content,
                    token_count=chunk.token_count,
                    embedding=vec,
                    metadata_json={
                        **(chunk.metadata or {}),
                        "model": result.model,
                        "provider": result.provider,
                    },
                )
            )
            inserted += 1

    await session.flush()
    logger.info("index_document done doc_id=%s chunks=%d", doc.id, inserted)
    return inserted
