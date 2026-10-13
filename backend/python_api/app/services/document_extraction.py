"""Extract plain text from uploaded files.

Phase 6 supports:
- application/pdf      via pypdf
- text/plain           direct read
- text/markdown        direct read
- Other types          return empty text and let the analysis pipeline
                       fall back to metadata heuristics.
"""
from __future__ import annotations

import io
import logging

from pypdf import PdfReader

logger = logging.getLogger(__name__)


class ExtractionResult:
    def __init__(self, text: str, page_count: int | None = None) -> None:
        self.text = text
        self.page_count = page_count


def extract_text(content: bytes, mime_type: str) -> ExtractionResult:
    """Extract text from a document's raw bytes."""
    mime = (mime_type or "").lower()

    if mime == "application/pdf" or content[:4] == b"%PDF":
        return _extract_pdf(content)

    if mime.startswith("text/"):
        return _extract_text(content)

    # Unknown types: return empty, the classifier will rely on metadata.
    logger.info("extraction_unsupported mime=%s", mime_type)
    return ExtractionResult(text="")


def _extract_pdf(content: bytes) -> ExtractionResult:
    try:
        reader = PdfReader(io.BytesIO(content))
        pages = reader.pages
        parts: list[str] = []
        for page in pages:
            try:
                parts.append(page.extract_text() or "")
            except Exception:  # noqa: BLE001
                # Bad page — skip silently, keep the rest.
                parts.append("")
        text = "\n\n".join(p.strip() for p in parts if p).strip()
        return ExtractionResult(text=text, page_count=len(pages))
    except Exception as exc:  # noqa: BLE001
        logger.warning("pdf_extraction_failed error=%s", exc)
        return ExtractionResult(text="", page_count=None)


def _extract_text(content: bytes) -> ExtractionResult:
    for encoding in ("utf-8", "latin-1", "cp1252"):
        try:
            return ExtractionResult(text=content.decode(encoding))
        except UnicodeDecodeError:
            continue
    return ExtractionResult(text="")
