from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
    conversation_id: str | None = None
    socratic_override: bool | None = None


class ChatResponseOut(BaseModel):
    conversation_id: str
    reply: str
    intent: str
    tools_used: list[str]
    source_document_id: str | None = None
    style_preferences: dict = {}


class ConversationOut(BaseModel):
    id: str
    title: str | None

    class Config:
        from_attributes = True


class MessageOut(BaseModel):
    id: str
    role: str
    content: str

    class Config:
        from_attributes = True


class VoiceChatResponseOut(BaseModel):
    conversation_id: str
    transcript: str
    reply: str
    intent: str
    tools_used: list[str]
    source_document_id: str | None = None
    style_preferences: dict = {}
    audio_reply_base64: str | None = None


class VisionChatResponseOut(BaseModel):
    conversation_id: str
    extracted_question: str
    used_vision_model: bool
    reply: str
    intent: str
    tools_used: list[str]
    source_document_id: str | None = None
    style_preferences: dict = {}
