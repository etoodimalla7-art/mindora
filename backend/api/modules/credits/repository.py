from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.credits.models import CreditAccount, CreditTransaction, Download
from api.modules.credits.rules import NEW_USER_FREE_CREDITS


class CreditsRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_or_create_account(self, user_id: str) -> CreditAccount:
        uid = to_uuid(user_id)
        result = await self.db.execute(select(CreditAccount).where(CreditAccount.user_id == uid))
        account = result.scalar_one_or_none()
        if account:
            return account
        account = CreditAccount(user_id=uid, balance=NEW_USER_FREE_CREDITS)
        self.db.add(account)
        await self.db.commit()
        await self.db.refresh(account)
        return account

    async def record_transaction(self, user_id: str, delta: int, reason: str, ref_id: str | None) -> CreditTransaction:
        account = await self.get_or_create_account(user_id)
        account.balance += delta
        transaction = CreditTransaction(user_id=to_uuid(user_id), delta=delta, reason=reason, ref_id=ref_id)
        self.db.add(transaction)
        await self.db.commit()
        await self.db.refresh(transaction)
        return transaction

    async def list_transactions(self, user_id: str) -> list[CreditTransaction]:
        result = await self.db.execute(
            select(CreditTransaction)
            .where(CreditTransaction.user_id == to_uuid(user_id))
            .order_by(CreditTransaction.created_at.desc())
        )
        return list(result.scalars().all())

    async def record_download(self, user_id: str, resource_type: str, resource_id: str) -> Download:
        download = Download(
            user_id=to_uuid(user_id), resource_type=resource_type, resource_id=resource_id,
            downloaded_at=datetime.now(timezone.utc),
        )
        self.db.add(download)
        await self.db.commit()
        await self.db.refresh(download)
        return download

    async def list_downloads(self, user_id: str) -> list[Download]:
        result = await self.db.execute(
            select(Download).where(Download.user_id == to_uuid(user_id)).order_by(Download.downloaded_at.desc())
        )
        return list(result.scalars().all())
