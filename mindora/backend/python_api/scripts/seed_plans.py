"""Seed the 3 default MINDORA subscription plans.

Run: poetry run python scripts/seed_plans.py
"""
from __future__ import annotations

import asyncio

from sqlalchemy import select

from app.db.session import AsyncSessionLocal
from app.models.subscription import (
    CYCLE_MONTHLY,
    CYCLE_QUARTERLY,
    CYCLE_YEARLY,
    TIER_PREMIUM,
    TIER_STUDENT,
    Plan,
)


DEFAULT_PLANS = [
    {
        "code": "student_monthly",
        "name": "Student Monthly",
        "description": "Unlimited downloads, all AI features. Cancel anytime.",
        "tier": TIER_STUDENT,
        "amount_minor": 250000,
        "currency": "XAF",
        "billing_cycle": CYCLE_MONTHLY,
        "features": {
            "unlimited_downloads": True,
            "ai_chat_unlimited": True,
            "mock_exams_unlimited": True,
            "priority_support": False,
        },
        "sort_order": 10,
    },
    {
        "code": "student_quarterly",
        "name": "Student Quarterly",
        "description": "Save 15% with a quarterly plan.",
        "tier": TIER_STUDENT,
        "amount_minor": 637500,
        "currency": "XAF",
        "billing_cycle": CYCLE_QUARTERLY,
        "features": {
            "unlimited_downloads": True,
            "ai_chat_unlimited": True,
            "mock_exams_unlimited": True,
            "priority_support": False,
        },
        "sort_order": 20,
    },
    {
        "code": "premium_yearly",
        "name": "Premium Yearly",
        "description": "Best value. Unlimited everything plus priority support.",
        "tier": TIER_PREMIUM,
        "amount_minor": 2000000,
        "currency": "XAF",
        "billing_cycle": CYCLE_YEARLY,
        "features": {
            "unlimited_downloads": True,
            "ai_chat_unlimited": True,
            "mock_exams_unlimited": True,
            "priority_support": True,
            "early_access": True,
        },
        "sort_order": 30,
    },
]


async def main() -> None:
    async with AsyncSessionLocal() as session:
        for spec in DEFAULT_PLANS:
            existing = (
                await session.execute(
                    select(Plan).where(Plan.code == spec["code"])
                )
            ).scalar_one_or_none()
            if existing:
                print(f"  ↻ {spec['code']} already exists")
                continue
            session.add(Plan(**spec))
            print(f"  ✓ created {spec['code']}")
        await session.commit()
        print("Done.")


if __name__ == "__main__":
    print("Seeding default MINDORA plans...")
    asyncio.run(main())
