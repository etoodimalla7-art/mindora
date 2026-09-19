"""
AI_ARCHITECTURE.md's pipeline, Phase 8 scope (text chat only):
INTENT DETECTION -> CONTEXT ANALYSIS -> TOOL SELECTION -> EXECUTION ->
SOURCE VALIDATION -> RESPONSE GENERATION. Voice, vision, the math
solver, and web search plug into this same shape in later phases
(13, 45, 46) by adding more branches to `handle()` and more entries in
`tools_used` — nothing about the pipeline's structure needs to change.
"""
from dataclasses import dataclass, field

from api.integrations.llm_provider import LLMProvider
from api.modules.ai_chat.course_retriever import retrieve_course_context
from api.modules.ai_chat.intent import classify_intent
from api.modules.ai_chat.tutor_style import build_style_instructions, detect_style_request, merge_style_preferences

SYSTEM_PROMPT_BASE = (
    "You are the AI tutor inside MINDORA, an education platform. Be patient, "
    "encouraging, and academically rigorous. Never fabricate sources or "
    "citations. When given course material, clearly distinguish it from your "
    "own general knowledge in your answer (section 16/76 of the product spec)."
)


@dataclass
class OrchestratorResult:
    reply: str
    intent: str
    tools_used: list[str] = field(default_factory=list)
    source_document_id: str | None = None
    style_preferences: dict = field(default_factory=dict)


class ChatOrchestrator:
    def __init__(self, llm_provider: LLMProvider, course_documents_provider):
        """
        course_documents_provider: async callable(user_id) ->
        list[(document_id, extracted_text)]. Injected so this class has
        no direct DB dependency — same pattern as
        DocumentAnalysisPipeline (Phase 5) — and is fully unit-testable
        with a fake provider.
        """
        self.llm_provider = llm_provider
        self.course_documents_provider = course_documents_provider

    async def handle(
        self,
        user_id: str,
        message: str,
        style_preferences: dict | None = None,
        socratic_override: bool | None = None,
    ) -> OrchestratorResult:
        existing_prefs = style_preferences or {}
        detected_updates = detect_style_request(message)
        if socratic_override is not None:
            # An explicit UI toggle (section 37) always wins over text
            # detection for the message that sent it.
            detected_updates["socratic"] = socratic_override
        merged_prefs = merge_style_preferences(existing_prefs, detected_updates)
        style_instructions = build_style_instructions(merged_prefs)

        intent = classify_intent(message)

        if intent in ("greeting", "empty"):
            # TOOL SELECTION: a greeting needs no retrieval at all —
            # "the AI must not use every tool for every question" (section 15).
            reply = await self.llm_provider.complete(SYSTEM_PROMPT_BASE, message)
            return OrchestratorResult(reply=reply, intent=intent, tools_used=[], style_preferences=merged_prefs)

        documents = await self.course_documents_provider(user_id)
        match = retrieve_course_context(message, documents)

        if match:
            document_id, snippet = match
            system_prompt = (
                f"{SYSTEM_PROMPT_BASE}\n\nThe student's own course material contains "
                f'this relevant excerpt:\n"""\n{snippet}\n"""\nUse it as your primary '
                f"source and say so explicitly (e.g. \"From your course material...\"). "
                f"Supplement with general knowledge only where the excerpt is "
                f"insufficient, and label that supplement clearly."
            )
            tools_used = ["course_retriever"]
            source_document_id = document_id
        else:
            system_prompt = (
                f"{SYSTEM_PROMPT_BASE}\n\nNo matching material was found in this "
                f"student's uploaded courses, so answer from general knowledge and "
                f'say so (e.g. "I don\'t have this in your uploaded courses, but...").'
            )
            tools_used = ["general_knowledge"]
            source_document_id = None

        if style_instructions:
            system_prompt = f"{system_prompt}\n\n{style_instructions}"

        reply = await self.llm_provider.complete(system_prompt, message)
        return OrchestratorResult(
            reply=reply, intent=intent, tools_used=tools_used,
            source_document_id=source_document_id, style_preferences=merged_prefs,
        )
