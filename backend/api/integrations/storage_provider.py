"""
Object storage interface (Replaceability Matrix in ARCHITECTURE.md).
Swap `LocalDiskStorageProvider` for an S3-compatible adapter in
production without touching any service code.
"""
from abc import ABC, abstractmethod
from pathlib import Path
import uuid

from api.core.config import get_settings

settings = get_settings()


class StorageProvider(ABC):
    @abstractmethod
    async def save(self, content: bytes, filename: str) -> str:
        """Persists a file and returns a stable, fetchable file_url/key."""

    @abstractmethod
    async def get_public_url(self, file_key: str) -> str:
        ...

    @abstractmethod
    async def read(self, file_key: str) -> bytes:
        """Reads a previously saved file back — used by the analysis
        pipeline (Phase 5) to extract text without re-uploading."""


class LocalDiskStorageProvider(StorageProvider):
    """Dev-only stub. Replace with an S3/GCS adapter for production —
    same interface, no changes needed anywhere else in the codebase."""

    def __init__(self, base_dir: str = "./_dev_storage"):
        self.base_dir = Path(base_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)

    async def save(self, content: bytes, filename: str) -> str:
        key = f"{uuid.uuid4()}_{filename}"
        (self.base_dir / key).write_bytes(content)
        return key

    async def get_public_url(self, file_key: str) -> str:
        return f"/dev-storage/{file_key}"

    async def read(self, file_key: str) -> bytes:
        return (self.base_dir / file_key).read_bytes()


def get_storage_provider() -> StorageProvider:
    # Later: branch on settings.storage_provider ("s3", "gcs", ...) to
    # return the matching real adapter.
    return LocalDiskStorageProvider()
