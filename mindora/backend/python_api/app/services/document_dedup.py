"""Detect exact and near-duplicate documents."""
from __future__ import annotations

import hashlib
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.document import Document, DocumentDuplicate


def content_hash(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def text_hash(text: str) -> str:
    normalized = " ".join((text or "").lower().split())
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


async def find_duplicates(
    session: AsyncSession, doc: Document
) -> list[DocumentDuplicate]:
    """Return duplicate relationships for `doc`.

    Phase 6 rules:
      - exact hash match → similarity = 1.0
      - same text hash (normalized) → similarity = 0.98
    """
    results: list[DocumentDuplicate] = []

    if doc.content_hash:
        stmt = select(Document).where(
            Document.content_hash == doc.content_hash,
            Document.id != doc.id,
            Document.deleted_at.is_(None),
        )
        for candidate in (await session.execute(stmt)).scalars().all():
            results.append(
                DocumentDuplicate(
                    document_id=doc.id,
                    candidate_id=candidate.id,
                    similarity=1.0,
                    matched_on="content_hash",
                )
            )

    if doc.text_hash:
        stmt = select(Document).where(
            Document.text_hash == doc.text_hash,
            Document.id != doc.id,
            Document.deleted_at.is_(None),
        )
        seen = {r.candidate_id for r in results}
        for candidate in (await session.execute(stmt)).scalars().all():
            if candidate.id in seen:
                continue
            results.append(
                DocumentDuplicate(
                    document_id=doc.id,
                    candidate_id=candidate.id,
                    similarity=0.98,
                    matched_on="text_hash",
                )
            )

    return results


def has_blocking_duplicate(duplicates: list[DocumentDuplicate]) -> bool:
    """A blocking duplicate is an exact hash match."""
    return any(d.matched_on == "content_hash" for d in duplicates)


def top_duplicate(duplicates: list[DocumentDuplicate]) -> DocumentDuplicate | None:
    if not duplicates:
        return None
    return max(duplicates, key=lambda d: d.similarity)
