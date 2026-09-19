from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.admin.models import AuditLog


class AdminRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def record_audit_log(
        self, actor_id: str, action: str, target_type: str, target_id: str, detail: dict | None = None,
    ) -> AuditLog:
        entry = AuditLog(
            actor_id=to_uuid(actor_id), action=action, target_type=target_type,
            target_id=target_id, detail=detail or {},
        )
        self.db.add(entry)
        await self.db.commit()
        await self.db.refresh(entry)
        return entry

    async def list_audit_log(self, limit: int = 100) -> list[AuditLog]:
        result = await self.db.execute(select(AuditLog).order_by(AuditLog.created_at.desc()).limit(limit))
        return list(result.scalars().all())
