from datetime import datetime
from pydantic import BaseModel


class PlanOut(BaseModel):
    code: str
    name: str
    amount_minor_units: int
    currency: str
    interval: str


class SubscribeIn(BaseModel):
    plan_code: str


class SubscriptionOut(BaseModel):
    plan_code: str
    status: str
    current_period_end: datetime

    class Config:
        from_attributes = True
