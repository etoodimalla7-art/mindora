"""APScheduler-based recurring jobs for notifications.

Jobs run in-process (AsyncIOScheduler). Suitable for a single-instance
deployment (Render free tier). For multi-instance, migrate to a distributed
scheduler (e.g. Celery Beat + Redis).

All times are expressed in UTC. Local offset (Africa/Douala = UTC+1) is
applied when scheduling the daily jobs.
"""

from __future__ import annotations

import logging

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger

from app.db.session import AsyncSessionLocal
from app.services.notification.jobs import (
    job_scan_exam_countdown,
    job_scan_inactivity,
    job_scan_streaks,
    job_scan_subscriptions,
    job_scan_upcoming_sessions,
)

logger = logging.getLogger(__name__)

_scheduler: AsyncIOScheduler | None = None

# Local offset: Africa/Douala is UTC+1 (no DST)
_LOCAL_OFFSET_HOURS = 1


async def _run(job_coro) -> None:
    """Wrapper that opens a DB session and runs the job."""
    async with AsyncSessionLocal() as db:
        try:
            await job_coro(db)
            await db.commit()
        except Exception as exc:  # noqa: BLE001
            logger.exception("Scheduled job failed: %s", exc)
            await db.rollback()


def _wrap(job_fn):
    """Adapt a (db) -> coroutine job to APScheduler signature."""

    async def _inner() -> None:
        await _run(job_fn)

    return _inner


def build_scheduler() -> AsyncIOScheduler:
    """Create and configure the scheduler (does NOT start it)."""
    sched = AsyncIOScheduler(timezone="UTC")

    # --- Job 1 : upcoming sessions — every 5 minutes ---------------------
    sched.add_job(
        _wrap(job_scan_upcoming_sessions),
        trigger=IntervalTrigger(minutes=5),
        id="notif_scan_upcoming_sessions",
        name="Scan upcoming sessions (15 min window)",
        replace_existing=True,
        max_instances=1,
        coalesce=True,
    )

    # --- Job 2 : exam countdown — daily 09h local (08h UTC) --------------
    sched.add_job(
        _wrap(job_scan_exam_countdown),
        trigger=CronTrigger(hour=9 - _LOCAL_OFFSET_HOURS, minute=0),
        id="notif_scan_exam_countdown",
        name="Exam countdown (J-7/J-3/J-1)",
        replace_existing=True,
        max_instances=1,
        coalesce=True,
    )

    # --- Job 3 : streak alerts — daily 20h local (19h UTC) ---------------
    sched.add_job(
        _wrap(job_scan_streaks),
        trigger=CronTrigger(hour=20 - _LOCAL_OFFSET_HOURS, minute=0),
        id="notif_scan_streaks",
        name="Streak alerts (20h local)",
        replace_existing=True,
        max_instances=1,
        coalesce=True,
    )

    # --- Job 4 : inactivity — daily 10h local (09h UTC) ------------------
    sched.add_job(
        _wrap(job_scan_inactivity),
        trigger=CronTrigger(hour=10 - _LOCAL_OFFSET_HOURS, minute=0),
        id="notif_scan_inactivity",
        name="Inactivity nudges (>3 days)",
        replace_existing=True,
        max_instances=1,
        coalesce=True,
    )

    # --- Job 5 : subscription expiry — daily 10h30 local (09h30 UTC) -----
    sched.add_job(
        _wrap(job_scan_subscriptions),
        trigger=CronTrigger(hour=10 - _LOCAL_OFFSET_HOURS, minute=30),
        id="notif_scan_subscriptions",
        name="Subscription expiry (J-7/J-1)",
        replace_existing=True,
        max_instances=1,
        coalesce=True,
    )

    return sched


def start_scheduler() -> AsyncIOScheduler:
    """Start the singleton scheduler (idempotent)."""
    global _scheduler
    if _scheduler is not None:
        logger.info("Scheduler already running")
        return _scheduler

    _scheduler = build_scheduler()
    _scheduler.start()
    logger.info(
        "Notification scheduler started with %d jobs",
        len(_scheduler.get_jobs()),
    )
    return _scheduler


def stop_scheduler() -> None:
    """Stop the singleton scheduler if running."""
    global _scheduler
    if _scheduler is None:
        return
    try:
        _scheduler.shutdown(wait=False)
        logger.info("Notification scheduler stopped")
    except Exception as exc:  # noqa: BLE001
        logger.exception("Scheduler shutdown failed: %s", exc)
    finally:
        _scheduler = None


def get_scheduler() -> AsyncIOScheduler | None:
    return _scheduler
