"""
Sections 21/25: exact + near-duplicate detection. Exact match is a
content hash; near-duplicate is a text-similarity ratio against other
documents' extracted text. This is O(n) over existing documents, which
is fine at seed scale — swap for embedding + vector-index similarity
search (see ARCHITECTURE.md's vector store) once the corpus grows past
a few thousand documents. Per section 25: flag, never auto-reject.
"""
import difflib
import hashlib

NEAR_DUPLICATE_THRESHOLD = 0.85


def content_hash(text: str) -> str | None:
    normalized = " ".join(text.lower().split())
    if not normalized:
        return None
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


def similarity_ratio(text_a: str, text_b: str) -> float:
    # quick_ratio trades a little accuracy for speed — fine for a
    # "worth a human look" signal rather than a legal determination.
    return difflib.SequenceMatcher(None, text_a[:4000], text_b[:4000]).quick_ratio()


def find_best_match(
    target_text: str,
    target_hash: str | None,
    candidates: list[tuple[str, str | None, str | None]],
) -> tuple[str | None, float]:
    """
    candidates: list of (document_id, content_hash, extracted_text) for
    other documents. Returns (matching_document_id, similarity) where
    similarity is 1.0 for an exact hash match, or the best fuzzy ratio
    above the threshold, or (None, 0.0) if nothing looks like a duplicate.
    """
    if target_hash:
        for doc_id, chash, _ in candidates:
            if chash and chash == target_hash:
                return doc_id, 1.0

    best_id, best_score = None, 0.0
    for doc_id, _, text in candidates:
        if not text:
            continue
        score = similarity_ratio(target_text, text)
        if score > best_score:
            best_id, best_score = doc_id, score

    if best_score >= NEAR_DUPLICATE_THRESHOLD:
        return best_id, best_score
    return None, 0.0
