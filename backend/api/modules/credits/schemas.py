from datetime import datetime
from pydantic import BaseModel


class CreditBalanceOut(BaseModel):
    balance: int


class CreditTransactionOut(BaseModel):
    id: str
    delta: int
    reason: str
    ref_id: str | None
    created_at: datetime

    class Config:
        from_attributes = True


class DownloadOut(BaseModel):
    id: str
    resource_type: str
    resource_id: str
    downloaded_at: datetime

    class Config:
        from_attributes = True
