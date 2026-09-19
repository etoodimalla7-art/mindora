from api.core.errors import NotFoundError, ValidationFailedError
from api.modules.ai_chat.orchestrator import ChatOrchestrator
from api.modules.ai_chat.repository import AiChatRepository

MAX_AUDIO_BYTES = 15 * 1024 * 1024  # 15 MB — a few minutes of compressed speech
MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10 MB — generous for a phone camera photo


class AiChatService:
    def __init__(self, repo: AiChatRepository, orchestrator: ChatOrchestrator, speech_provider=None, image_text_extractor=None):
        self.repo = repo
        self.orchestrator = orchestrator
        self.speech_provider = speech_provider
        self.image_text_extractor = image_text_extractor

    async def send_message(
        self, user_id: str, message: str, conversation_id: str | None, socratic_override: bool | None = None
    ):
        if not message.strip():
            raise ValidationFailedError("Please type a message.")

        if conversation_id:
            conversation = await self.repo.get_owned_conversation(conversation_id, user_id)
            if not conversation:
                raise NotFoundError("We couldn't find this conversation.")
        else:
            conversation = await self.repo.create_conversation(user_id, title=message.strip()[:60])

        await self.repo.add_message(str(conversation.id), "user", message)
        result = await self.orchestrator.handle(
            user_id, message, conversation.style_preferences or {}, socratic_override,
        )
        await self.repo.add_message(
            str(conversation.id), "assistant", result.reply,
            tool_trace={
                "intent": result.intent,
                "tools_used": result.tools_used,
                "source_document_id": result.source_document_id,
            },
        )
        await self.repo.update_style_preferences(str(conversation.id), result.style_preferences)
        return conversation, result

    async def list_conversations(self, user_id: str):
        return await self.repo.list_conversations(user_id)

    async def get_conversation_messages(self, conversation_id: str, user_id: str):
        conversation = await self.repo.get_owned_conversation(conversation_id, user_id)
        if not conversation:
            raise NotFoundError("We couldn't find this conversation.")
        return await self.repo.list_messages(conversation_id)

    async def send_voice_message(
        self, user_id: str, audio_bytes: bytes, content_type: str, conversation_id: str | None = None,
    ):
        """
        Section 43: Student speaks -> speech recognition -> AI
        processing -> voice synthesis -> student listens. Transcription
        and synthesis are delegated to `speech_provider`; everything
        after transcription reuses `send_message` — the exact same
        tested pipeline as text chat, so voice input carries none of
        text chat's already-verified risk (course retrieval, style
        preferences, persistence) as new, unverified surface.
        """
        if not audio_bytes:
            raise ValidationFailedError("No audio was received. Please try again.")
        if len(audio_bytes) > MAX_AUDIO_BYTES:
            raise ValidationFailedError("That recording is too long. Please send a shorter clip.")
        try:
            transcript = await self.speech_provider.transcribe(audio_bytes, content_type)
        except ValueError as exc:
            raise ValidationFailedError("We couldn't hear anything in that recording. Please try again.") from exc

        conversation, result = await self.send_message(user_id, transcript, conversation_id)
        audio_reply = await self.speech_provider.synthesize(result.reply)
        return conversation, result, transcript, audio_reply

    async def send_vision_message(
        self, user_id: str, image_bytes: bytes, content_type: str, conversation_id: str | None = None,
    ):
        """
        Section 44: Camera -> image processing -> OCR/Vision -> question
        understanding -> ... -> educational explanation. OCR runs first
        (cheap, works with no LLM call); if it finds nothing usable, a
        vision-capable LLM reads the image directly. Either way the
        extracted question text flows into the same tested
        `send_message` pipeline as typed and spoken questions.
        """
        if not image_bytes:
            raise ValidationFailedError("No image was received. Please try again.")
        if len(image_bytes) > MAX_IMAGE_BYTES:
            raise ValidationFailedError("That image is too large. Please try a smaller photo.")

        ocr_text = self.image_text_extractor(image_bytes, content_type) if self.image_text_extractor else ""
        used_vision_model = False

        if ocr_text and len(ocr_text) > 5:
            extracted_question = ocr_text
        else:
            try:
                extracted_question = await self.orchestrator.llm_provider.complete_with_image(
                    "Transcribe the question shown in this image exactly, with no commentary or extra text.",
                    "Transcribe the question in this image.",
                    image_bytes, content_type,
                )
                used_vision_model = True
            except NotImplementedError as exc:
                raise ValidationFailedError(
                    "We couldn't read this image. Please try a clearer photo or type your question instead."
                ) from exc

        conversation, result = await self.send_message(user_id, extracted_question, conversation_id)
        return conversation, result, extracted_question, used_vision_model
