"""
Section 44's camera pipeline, the OCR half: Camera -> Image processing
-> OCR/Vision -> ... The extractor call is wrapped as a plain function
(image_bytes, content_type) -> extracted text, injected into
AiChatService rather than hardcoded, so tests can substitute a
deterministic fake regardless of whether Tesseract is actually
installed on the host running the test.
"""
from api.integrations.text_extraction import TextExtractionError, get_extractor


def extract_text_from_image(image_bytes: bytes, content_type: str) -> str:
    extension = ".png" if "png" in content_type else ".jpg"
    extractor = get_extractor(extension)
    if not extractor:
        return ""
    try:
        text, _page_count = extractor.extract(image_bytes)
        return (text or "").strip()
    except TextExtractionError:
        return ""
