from api.core.errors import ValidationFailedError
from api.modules.credits.repository import CreditsRepository
from api.modules.credits.rules import DOWNLOAD_COST, can_download


class CreditsService:
    def __init__(self, repo: CreditsRepository):
        self.repo = repo

    async def get_balance(self, user_id: str) -> int:
        account = await self.repo.get_or_create_account(user_id)
        return account.balance

    async def list_history(self, user_id: str):
        return await self.repo.list_transactions(user_id)

    async def list_downloads(self, user_id: str):
        return await self.repo.list_downloads(user_id)

    async def grant(self, user_id: str, amount: int, reason: str, ref_id: str | None = None):
        return await self.repo.record_transaction(user_id, amount, reason, ref_id)

    async def spend_for_download(
        self, user_id: str, resource_type: str, resource_id: str, has_active_subscription: bool,
    ):
        """
        Section 29: subscribed users download for free, no credit
        spent. Everyone else needs DOWNLOAD_COST credits, and the
        download only happens if payment (in credits) actually
        succeeds — never record a download the student didn't pay for.
        """
        balance = await self.get_balance(user_id)
        if not can_download(balance, has_active_subscription):
            raise ValidationFailedError(
                "You're out of downloads. Subscribe or contribute approved documents to unlock more."
            )
        if not has_active_subscription:
            await self.repo.record_transaction(user_id, -DOWNLOAD_COST, "download", resource_id)
        return await self.repo.record_download(user_id, resource_type, resource_id)
