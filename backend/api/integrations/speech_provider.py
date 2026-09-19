"""
Speech provider interface (Replaceability Matrix) for section 43's
speech-to-text/text-to-speech. `MockSpeechProvider` is a deterministic,
no-network dev stand-in — same pattern as LLMProvider/StorageProvider/
EmailProvider. This codebase can't verify real transcription/synthesis
quality without a live audio pipeline and a provider API key — like
AnthropicLLMProvider in Phase 8, only the interface, the dev stub, and
the code that calls them are exercised here; a real adapter (e.g. a
hosted Whisper-compatible STT API and a TTS API) plugs in behind the
same two methods with no other code changing.
"""
from abc import ABC, abstractmethod


class SpeechProvider(ABC):
    @abstractmethod
    async def transcribe(self, audio_bytes: bytes, content_type: str) -> str:
        ...

    @abstractmethod
    async def synthesize(self, text: str) -> bytes | None:
        """Returns audio bytes, or None if synthesis isn't available
        (the mock provider, or a real provider that's temporarily
        down) — callers must handle a text-only fallback gracefully,
        never assume audio always comes back."""


class MockSpeechProvider(SpeechProvider):
    async def transcribe(self, audio_bytes: bytes, content_type: str) -> str:
        if not audio_bytes:
            raise ValueError("No audio received.")
        return "[dev-mock transcription — configure a real STT provider for actual speech recognition]"

    async def synthesize(self, text: str) -> bytes | None:
        return None  # no real TTS without a configured provider


def get_speech_provider() -> SpeechProvider:
    # Later: branch on settings to return a real STT/TTS adapter.
    return MockSpeechProvider()
