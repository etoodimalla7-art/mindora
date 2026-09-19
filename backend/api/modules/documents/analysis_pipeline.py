"""
Section 21's pipeline, steps 3-9 (TEXT/OCR EXTRACTION through DUPLICATE
DETECTION). File validation (step 2) already happened at upload time;
moderation/final decision (steps 11-12) stay a human/admin workflow —
this pipeline produces the evidence for that decision, it doesn't make
it alone.
"""
from dataclasses import dataclass

from api.integrations.text_extraction import TextExtractionError, get_extractor
from api.modules.documents.classification import compute_quality_score, detect_level, detect_subject
from api.modules.documents.duplicate_detection import content_hash, find_best_match
from api.modules.documents.language import check_language_mismatch, detect_language


@dataclass
class AnalysisResult:
    extracted_text: str
    content_hash: str | None
    page_count: int | None
    detected_language: str | None
    language_mismatch: str | None
    detected_subject: str | None
    detected_level: str | None
    quality_score: float
    duplicate_of_id: str | None
    similarity_score: float


class DocumentAnalysisPipeline:
    def __init__(self, other_documents_provider):
        """
        other_documents_provider: async callable(exclude_document_id) ->
        list[(document_id, content_hash, extracted_text)] for existing
        documents to compare against — injected so this class has no
        direct DB dependency and stays unit-testable.
        """
        self._other_documents_provider = other_documents_provider

    async def run(
        self,
        *,
        document_id: str,
        file_extension: str,
        file_content: bytes,
        declared_language: str | None,
    ) -> AnalysisResult:
        extractor = get_extractor(file_extension)
        text, page_count = "", None
        if extractor:
            try:
                text, page_count = extractor.extract(file_content)
            except TextExtractionError:
                raise  # caller maps this to a safe user-facing message

        detected_language = detect_language(text) if text else None
        language_mismatch = check_language_mismatch(declared_language, detected_language)
        detected_subject = detect_subject(text) if text else None
        detected_level = detect_level(text) if text else None
        quality_score = compute_quality_score(text)
        chash = content_hash(text)

        candidates = await self._other_documents_provider(document_id)
        duplicate_of_id, similarity = find_best_match(text, chash, candidates)

        return AnalysisResult(
            extracted_text=text,
            content_hash=chash,
            page_count=page_count,
            detected_language=detected_language,
            language_mismatch=language_mismatch,
            detected_subject=detected_subject,
            detected_level=detected_level,
            quality_score=quality_score,
            duplicate_of_id=duplicate_of_id,
            similarity_score=similarity,
        )
