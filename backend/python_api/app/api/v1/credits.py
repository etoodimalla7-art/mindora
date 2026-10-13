"""Credit endpoints."""
from __future__ import annotations

from fastapi import APIRouter

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.credit import CreditBalanceOut, CreditEntryOut
from app.services.credit_service import (
    CONTRIBUTION_REWARD,
    DOWNLOAD_COST,
    SIGNUP_BONUS,
    CreditService,
)

router = APIRouter()


@router.get("", response_model=CreditBalanceOut)
async def get_balance(session: SessionDep, user_id: CurrentUserId) -> CreditBalanceOut:
    svc = CreditService(session)
    balance = await svc.balance(user_id)
    history = await svc.history(user_id)
    return CreditBalanceOut(
        balance=balance,
        signup_bonus=SIGNUP_BONUS,
        contribution_reward=CONTRIBUTION_REWARD,
        download_cost=DOWNLOAD_COST,
        history=[CreditEntryOut.model_validate(h) for h in history],
    )
