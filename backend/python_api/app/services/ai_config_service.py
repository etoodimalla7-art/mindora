"""AI config service — read/update/publish/test prompts."""
from __future__ import annotations

import logging
import time
import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError, ValidationError
from app.integrations.ai.factory import get_chat_provider
from app.integrations.ai.provider import ChatMessage
from app.models.ai_config import AIConfig, AIConfigVersion
from app.schemas.admin_ai import AIConfigOut, AIConfigUpdate, AIVersionOut

logger = logging.getLogger(__name__)


class AIConfigService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_active(self) -> AIConfigOut:
        cfg = (
            await self.session.execute(
                select(AIConfig).where(AIConfig.is_active.is_(True)).limit(1)
            )
        ).scalar_one_or_none()
        if not cfg:
            raise NotFoundError("No active AI config found.")
        return AIConfigOut.model_validate(cfg)

    async def update(
        self,
        payload: AIConfigUpdate,
        updated_by: uuid.UUID | None = None,
    ) -> AIConfigOut:
        cfg = (
            await self.session.execute(
                select(AIConfig).where(AIConfig.is_active.is_(True)).limit(1)
            )
        ).scalar_one_or_none()
        if not cfg:
            raise NotFoundError("No active AI config found.")

        if payload.system_prompt is not None:
            cfg.system_prompt = payload.system_prompt
        if payload.model is not None:
            cfg.model = payload.model
        if payload.temperature is not None:
            cfg.temperature = payload.temperature
        if payload.max_tokens is not None:
            cfg.max_tokens = payload.max_tokens
        if payload.language is not None:
            cfg.language = payload.language

        cfg.updated_by = updated_by
        cfg.updated_at = datetime.now(timezone.utc)
        await self.session.commit()
        await self.session.refresh(cfg)
        return AIConfigOut.model_validate(cfg)

    async def publish(
        self,
        notes: str | None,
        published_by: uuid.UUID | None = None,
    ) -> AIVersionOut:
        cfg = (
            await self.session.execute(
                select(AIConfig).where(AIConfig.is_active.is_(True)).limit(1)
            )
        ).scalar_one_or_none()
        if not cfg:
            raise NotFoundError("No active AI config found.")

        # Next version number
        last_v = (
            await self.session.execute(
                select(AIConfigVersion.version)
                .where(AIConfigVersion.config_id == cfg.id)
                .order_by(AIConfigVersion.version.desc())
                .limit(1)
            )
        ).scalar_one_or_none()
        next_v = (last_v or 0) + 1

        version = AIConfigVersion(
            config_id=cfg.id,
            version=next_v,
            system_prompt=cfg.system_prompt,
            model=cfg.model,
            temperature=cfg.temperature,
            max_tokens=cfg.max_tokens,
            notes=notes,
            published_by=published_by,
        )
        self.session.add(version)
        await self.session.commit()
        await self.session.refresh(version)
        return AIVersionOut.model_validate(version)

    async def list_versions(self, limit: int = 50) -> list[AIVersionOut]:
        cfg = (
            await self.session.execute(
                select(AIConfig).where(AIConfig.is_active.is_(True)).limit(1)
            )
        ).scalar_one_or_none()
        if not cfg:
            return []
        rows = (
            await self.session.execute(
                select(AIConfigVersion)
                .where(AIConfigVersion.config_id == cfg.id)
                .order_by(AIConfigVersion.version.desc())
                .limit(limit)
            )
        ).scalars().all()
        return [AIVersionOut.model_validate(v) for v in rows]

    async def activate_version(
        self,
        version_id: uuid.UUID,
        updated_by: uuid.UUID | None = None,
    ) -> AIConfigOut:
        v = await self.session.get(AIConfigVersion, version_id)
        if not v:
            raise NotFoundError("Version not found.")
        cfg = await self.session.get(AIConfig, v.config_id)
        if not cfg:
            raise NotFoundError("Config not found.")
        cfg.system_prompt = v.system_prompt
        cfg.model = v.model
        cfg.temperature = v.temperature
        cfg.max_tokens = v.max_tokens
        cfg.updated_by = updated_by
        cfg.updated_at = datetime.now(timezone.utc)
        await self.session.commit()
        await self.session.refresh(cfg)
        return AIConfigOut.model_validate(cfg)

    async def test(
        self,
        message: str,
        system_prompt: str | None = None,
        model: str | None = None,
        temperature: float | None = None,
        max_tokens: int | None = None,
    ) -> dict:
        cfg = (
            await self.session.execute(
                select(AIConfig).where(AIConfig.is_active.is_(True)).limit(1)
            )
        ).scalar_one_or_none()

        prompt = system_prompt or (cfg.system_prompt if cfg else "")
        mdl = model or (cfg.model if cfg else None)
        temp = temperature if temperature is not None else (cfg.temperature if cfg else 0.5)
        max_tok = max_tokens or (cfg.max_tokens if cfg else 1200)

        if not prompt:
            raise ValidationError("No system prompt to test.")

        provider = get_chat_provider()
        messages = [
            ChatMessage(role="system", content=prompt),
            ChatMessage(role="user", content=message),
        ]
        start = time.monotonic()
        resp = await provider.chat(
            messages,
            model=mdl,
            temperature=temp,
            max_tokens=max_tok,
        )
        elapsed = int((time.monotonic() - start) * 1000)
        return {
            "response": resp.content,
            "model": resp.model,
            "provider": resp.provider,
            "usage": resp.usage or {},
            "elapsed_ms": elapsed,
        }
