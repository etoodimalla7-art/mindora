"""
Section 16: course-aware retrieval, v1. Real semantic search needs
embeddings + a vector store (see ARCHITECTURE.md's VectorStore
interface, planned for pgvector) — this is a keyword-overlap scorer
over each document's already-extracted text (Phase 5's
DocumentAnalysis.extracted_text). Good enough to surface an obviously
relevant course document, and cheap enough to need no extra infra.
Swap for embedding similarity later; the return shape — a ranked
(document_id, snippet) match or None — stays the same, so nothing
calling this needs to change.
"""
import re

RELEVANCE_THRESHOLD = 0.12  # fraction of the query's distinct (non-stopword) words that must appear

# Common English/French function words carry no topical signal and were
# causing false-positive matches (e.g. "what is the capital of France"
# scoring as relevant to a calculus document purely on "the"/"of"/"is").
_STOPWORDS = {
    "the", "a", "an", "is", "are", "was", "were", "be", "been", "of", "in", "on",
    "at", "to", "for", "with", "and", "or", "but", "as", "by", "this", "that",
    "it", "what", "which", "who", "whom", "whose", "how", "why", "when", "where",
    "do", "does", "did", "can", "could", "will", "would", "should",
    "le", "la", "les", "un", "une", "des", "de", "du", "et", "ou", "que", "qui",
    "est", "sont", "dans", "sur", "pour", "avec", "comment", "pourquoi", "quand",
}


def _tokenize(text: str) -> set[str]:
    words = re.findall(r"[a-zà-ÿ]+", text.lower())
    return {w for w in words if w not in _STOPWORDS}


def score_document(query: str, document_text: str) -> float:
    query_words = _tokenize(query)
    if not query_words or not document_text:
        return 0.0
    doc_words = _tokenize(document_text)
    return len(query_words & doc_words) / len(query_words)


def find_best_snippet(query: str, document_text: str, window: int = 400) -> str:
    """A short excerpt around the first matching query word, so the
    tutor can say 'from your course material' without the whole
    document going into the prompt."""
    query_words = _tokenize(query)
    lowered = document_text.lower()
    for word in query_words:
        idx = lowered.find(word)
        if idx != -1:
            start = max(0, idx - window // 2)
            return document_text[start:start + window].strip()
    return document_text[:window].strip()


def retrieve_course_context(query: str, documents: list[tuple[str, str]]) -> tuple[str, str] | None:
    """
    documents: [(document_id, extracted_text), ...] — already scoped to
    this student's own documents by the caller. Returns (document_id,
    snippet) for the single best match above threshold, or None if
    nothing is relevant enough to trust as course material — callers
    fall back to general knowledge rather than forcing a weak match.
    """
    best_id, best_score, best_text = None, 0.0, None
    for doc_id, text in documents:
        score = score_document(query, text)
        if score > best_score:
            best_id, best_score, best_text = doc_id, score, text
    if best_id is None or best_score < RELEVANCE_THRESHOLD:
        return None
    return best_id, find_best_snippet(query, best_text)
