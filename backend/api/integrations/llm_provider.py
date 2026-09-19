"""
LLM provider interface (Replaceability Matrix in ARCHITECTURE.md).
`AnthropicLLMProvider` is the real production adapter shape;
`MockLLMProvider` is a deterministic, no-network stand-in so the
orchestrator and API layer are fully testable without a live API key —
same pattern as EmailProvider/StorageProvider in earlier phases.
"""
from abc import ABC, abstractmethod


class LLMProvider(ABC):
    @abstractmethod
    async def complete(self, system_prompt: str, user_message: str) -> str:
        ...

    async def complete_with_image(
        self, system_prompt: str, user_message: str, image_bytes: bytes, media_type: str
    ) -> str:
        """
        Default: not supported. Providers with real vision capability
        override this (section 44's vision-mode fallback when OCR finds
        nothing usable). Not abstract, because OCR text alone answers
        most textbook/handwritten questions — image understanding is a
        enhancement, not a hard requirement for every provider.
        """
        raise NotImplementedError("This provider doesn't support image input.")


class MockLLMProvider(LLMProvider):
    """Used until LLM_API_KEY is configured (see get_llm_provider()).
    Deterministic and network-free so tests and local dev work without
    credentials — echoes enough of the inputs to be visibly a stub, not
    a real answer."""

    async def complete(self, system_prompt: str, user_message: str) -> str:
        return (
            "[dev-mock response — configure LLM_API_KEY for real answers] "
            f'Here is a starting point for: "{user_message.strip()}"'
        )

    async def complete_with_image(
        self, system_prompt: str, user_message: str, image_bytes: bytes, media_type: str
    ) -> str:
        return (
            "[dev-mock vision response — configure LLM_API_KEY for real image "
            f"understanding] Received an image ({len(image_bytes)} bytes, {media_type})."
        )


class AnthropicLLMProvider(LLMProvider):
    """
    Production adapter. Talks to the Messages API directly over HTTPS
    (via httpx) rather than pulling in the full SDK as a dependency.
    `build_request_body` is split out as a pure function so the request
    shape is unit-testable without live credentials or a network call.
    """

    def __init__(self, api_key: str, model: str = "claude-sonnet-4-6"):
        self.api_key = api_key
        self.model = model

    def build_request_body(self, system_prompt: str, user_message: str) -> dict:
        return {
            "model": self.model,
            "max_tokens": 1024,
            "system": system_prompt,
            "messages": [{"role": "user", "content": user_message}],
        }

    def build_image_request_body(
        self, system_prompt: str, user_message: str, image_bytes: bytes, media_type: str
    ) -> dict:
        """Pure function (no network) — same testability rationale as
        build_request_body above."""
        import base64

        return {
            "model": self.model,
            "max_tokens": 1024,
            "system": system_prompt,
            "messages": [{
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": media_type,
                            "data": base64.b64encode(image_bytes).decode("ascii"),
                        },
                    },
                    {"type": "text", "text": user_message},
                ],
            }],
        }

    async def complete(self, system_prompt: str, user_message: str) -> str:
        import httpx

        body = self.build_request_body(system_prompt, user_message)
        headers = {
            "x-api-key": self.api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        }
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post("https://api.anthropic.com/v1/messages", json=body, headers=headers)
            response.raise_for_status()
            data = response.json()
            return "".join(
                block.get("text", "") for block in data.get("content", []) if block.get("type") == "text"
            )

    async def complete_with_image(
        self, system_prompt: str, user_message: str, image_bytes: bytes, media_type: str
    ) -> str:
        import httpx

        body = self.build_image_request_body(system_prompt, user_message, image_bytes, media_type)
        headers = {
            "x-api-key": self.api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        }
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post("https://api.anthropic.com/v1/messages", json=body, headers=headers)
            response.raise_for_status()
            data = response.json()
            return "".join(
                block.get("text", "") for block in data.get("content", []) if block.get("type") == "text"
            )


def get_llm_provider(api_key: str | None) -> LLMProvider:
    return AnthropicLLMProvider(api_key) if api_key else MockLLMProvider()
