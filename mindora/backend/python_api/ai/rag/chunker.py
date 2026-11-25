"""Chunk text into overlapping windows suitable for embedding."""
from __future__ import annotations

import re
from dataclasses import dataclass

# Chunk size (in characters) and overlap.
DEFAULT_CHUNK_SIZE = 1500
DEFAULT_OVERLAP = 200
MIN_CHUNK_SIZE = 200


@dataclass
class Chunk:
    index: int
    content: str
    token_count: int
    metadata: dict


def chunk_text(
    text: str,
    *,
    chunk_size: int = DEFAULT_CHUNK_SIZE,
    overlap: int = DEFAULT_OVERLAP,
) -> list[Chunk]:
    """Split text into overlapping chunks, respecting paragraph boundaries
    when possible."""
    if not text or not text.strip():
        return []

    # Normalize whitespace a bit.
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)

    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]

    chunks: list[Chunk] = []
    buffer = ""

    def flush(buf: str) -> None:
        nonlocal chunks
        buf = buf.strip()
        if len(buf) < MIN_CHUNK_SIZE and chunks:
            # Merge tiny trailing chunk into the previous one.
            prev = chunks[-1]
            prev.content = (prev.content + "\n\n" + buf).strip()
            prev.token_count = _estimate_tokens(prev.content)
            return
        if buf:
            chunks.append(
                Chunk(
                    index=len(chunks),
                    content=buf,
                    token_count=_estimate_tokens(buf),
                    metadata={},
                )
            )

    for para in paragraphs:
        # If adding this paragraph exceeds chunk_size, flush first.
        if len(buffer) + len(para) + 2 > chunk_size and buffer:
            flush(buffer)
            # Start a new buffer with some overlap from the previous chunk.
            tail = buffer[-overlap:] if overlap > 0 else ""
            buffer = tail + ("\n\n" if tail else "") + para
        else:
            buffer = (buffer + "\n\n" + para) if buffer else para

    if buffer:
        flush(buffer)

    return chunks


def _estimate_tokens(text: str) -> int:
    """Rough token estimate — 1 token ≈ 4 chars for English/French."""
    return max(1, len(text) // 4)
