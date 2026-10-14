"""Generate mock-exam questions from the student's documents.

Strategy:
  1. Pick the most relevant chunks from the student's approved documents
     (via the retriever) for the requested subject.
  2. Ask Gemini to produce a JSON array of questions strictly grounded in
     the provided excerpts.
  3. Parse and validate the response.
"""
from __future__ import annotations

import json
import logging
import re
import uuid
from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.ai.factory import get_chat_provider
from app.integrations.ai.provider import ChatMessage
from app.models.document import DOC_STATUS_APPROVED, Document
from app.models.document_chunk import DocumentChunk
from ai.rag.retriever import search_documents
from ai.rag.chunker import chunk_text  # noqa: F401  (may be used for fallback)

logger = logging.getLogger(__name__)


@dataclass
class GeneratedQuestion:
    position: int
    question_type: str  # mcq | true_false | short_answer
    prompt: str
    options: list[dict]
    correct_answer: str
    explanation: str
    difficulty: str
    metadata: dict


_SYSTEM = """You are a senior examiner for MINDORA, an academic platform.
You write examination questions strictly grounded in the source material.

You will receive:
  - a subject
  - a difficulty setting (easy | medium | hard | mixed)
  - a requested question count
  - a list of excerpts from the student's own documents

You must produce a JSON object:

{
  "questions": [
    {
      "type": "mcq" | "true_false" | "short_answer",
      "prompt": "<the question>",
      "options": [{"label": "A", "text": "..."}, ...],   // mcq only, 4 options
      "correct_answer": "<letter for mcq, 'true'/'false' for tf, or text for short>",
      "explanation": "<1-3 sentences explaining the correct answer>",
      "difficulty": "easy" | "medium" | "hard",
      "topic": "<short topic tag drawn from the excerpt>"
    }
  ]
}

Rules:
- Answer strictly from the excerpts. Do NOT invent facts.
- Prefer a mix of question types unless the difficulty says otherwise.
- For MCQ, always exactly 4 options labeled A, B, C, D.
- For true_false, correct_answer must be "true" or "false".
- For short_answer, correct_answer must be a concise model answer (one phrase).
- Never return more questions than requested. Return exactly the count asked.
- Output ONLY the JSON object, no markdown fences, no commentary.
"""


async def generate_questions(
    session: AsyncSession,
    *,
    user_id: uuid.UUID,
    subject: str,
    difficulty: str,
    count: int,
    document_ids: list[uuid.UUID] | None = None,
) -> list[GeneratedQuestion]:
    # 1. Gather context chunks.
    excerpts = await _gather_context(
        session,
        user_id=user_id,
        subject=subject,
        document_ids=document_ids or [],
        max_chunks=12,
    )
    if not excerpts:
        logger.warning("generate_questions_no_context user_id=%s subject=%s",
                       user_id, subject)
        return []

    context_block = "\n\n---\n\n".join(excerpts)[:14000]  # keep tokens sane

    # 2. Ask the LLM.
    provider = get_chat_provider()
    user_prompt = (
        f"Subject: {subject}\n"
        f"Difficulty: {difficulty}\n"
        f"Question count: {count}\n\n"
        f"Source excerpts:\n\n{context_block}\n"
    )

    try:
        response = await provider.chat(
            [
                ChatMessage(role="system", content=_SYSTEM),
                ChatMessage(role="user", content=user_prompt),
            ],
            temperature=0.5,
            json_mode=True,
            max_tokens=4000,
        )
    except Exception as exc:  # noqa: BLE001
        logger.error("generate_questions_llm_failed error=%s", exc)
        return []

    # 3. Parse + validate.
    data = _parse_json(response.content)
    if not data or "questions" not in data:
        logger.warning("generate_questions_bad_response")
        return []

    questions: list[GeneratedQuestion] = []
    for i, q in enumerate(data["questions"][:count]):
        qtype = str(q.get("type", "mcq")).lower()
        if qtype not in ("mcq", "true_false", "short_answer"):
            qtype = "mcq"

        options = q.get("options") or []
        if qtype != "mcq":
            options = []

        prompt = str(q.get("prompt", "")).strip()
        correct = str(q.get("correct_answer", "")).strip()
        if not prompt or not correct:
            continue

        questions.append(
            GeneratedQuestion(
                position=i,
                question_type=qtype,
                prompt=prompt,
                options=options,
                correct_answer=correct,
                explanation=str(q.get("explanation", "")).strip() or None,  # type: ignore[arg-type]
                difficulty=str(q.get("difficulty", difficulty)).lower(),
                metadata={
                    "topic": str(q.get("topic", "")).strip() or "general",
                    "source_chunks": excerpts[:3],  # keep a small sample
                },
            )
        )
    return questions


# ---------- Helpers ----------

async def _gather_context(
    session: AsyncSession,
    *,
    user_id: uuid.UUID,
    subject: str,
    document_ids: list[uuid.UUID],
    max_chunks: int,
) -> list[str]:
    """Return text chunks from the student's approved documents.

    If document_ids are provided, use them; otherwise, pull the most recent
    approved documents for the user and take chunks from them.
    """
    if document_ids:
        doc_filter = Document.id.in_(document_ids)
    else:
        doc_filter = Document.owner_id == user_id

    stmt = (
        select(DocumentChunk.content)
        .join(Document, Document.id == DocumentChunk.document_id)
        .where(
            doc_filter,
            Document.status == DOC_STATUS_APPROVED,
            Document.deleted_at.is_(None),
        )
        .order_by(DocumentChunk.created_at.desc())
        .limit(max_chunks)
    )
    rows = (await session.execute(stmt)).scalars().all()
    return [r for r in rows if r]


def _parse_json(text: str) -> dict | None:
    if not text:
        return None
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if not match:
            return None
        try:
            return json.loads(match.group(0))
        except json.JSONDecodeError:
            return None
