"""
Text/OCR extraction (section 21 pipeline step 3). One interface, one
adapter per file type, dispatched by extension — matches the same
Replaceability Matrix pattern as storage/email.
"""
from abc import ABC, abstractmethod
from io import BytesIO


class TextExtractionError(Exception):
    """Raised only for truly unreadable files (section 22) — never for
    'OCR found nothing', which is handled gracefully instead."""


class TextExtractor(ABC):
    @abstractmethod
    def extract(self, content: bytes) -> tuple[str, int | None]:
        """Returns (extracted_text, page_count). page_count is None when
        the format has no notion of pages (e.g. a single image)."""


class PdfTextExtractor(TextExtractor):
    def extract(self, content: bytes) -> tuple[str, int | None]:
        from pypdf import PdfReader

        try:
            reader = PdfReader(BytesIO(content))
        except Exception as exc:
            raise TextExtractionError(
                "We couldn't read this PDF. Please check it isn't password-protected or corrupted."
            ) from exc
        parts: list[str] = []
        for page in reader.pages:
            try:
                parts.append(page.extract_text() or "")
            except Exception:
                continue  # one bad page shouldn't fail the whole document
        return "\n".join(parts), len(reader.pages)


class DocxTextExtractor(TextExtractor):
    def extract(self, content: bytes) -> tuple[str, int | None]:
        from docx import Document as DocxDocument

        try:
            doc = DocxDocument(BytesIO(content))
        except Exception as exc:
            raise TextExtractionError("We couldn't read this Word document.") from exc
        return "\n".join(p.text for p in doc.paragraphs), None


class ImageOcrExtractor(TextExtractor):
    """
    Requires the Tesseract binary on the host — pytesseract is only a
    wrapper. If it isn't installed (or OCR simply finds nothing), we
    return empty text rather than failing the upload: OCR quality is a
    quality signal for review, not a hard gate on submission.
    """

    def extract(self, content: bytes) -> tuple[str, int | None]:
        try:
            import pytesseract
            from PIL import Image

            image = Image.open(BytesIO(content))
            text = pytesseract.image_to_string(image)
            return text, 1
        except Exception:
            return "", 1


_EXTRACTORS: dict[str, TextExtractor] = {
    ".pdf": PdfTextExtractor(),
    ".docx": DocxTextExtractor(),
    ".png": ImageOcrExtractor(),
    ".jpg": ImageOcrExtractor(),
    ".jpeg": ImageOcrExtractor(),
}


def get_extractor(extension: str) -> TextExtractor | None:
    return _EXTRACTORS.get(extension.lower())
