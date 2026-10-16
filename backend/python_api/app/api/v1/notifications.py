"""Notification endpoints."""
from __future__ import annotations

import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Response, status
from sqlalchemy import select

from app.api.deps import AdminUser, CurrentUserId, SessionDep
from app.core.errors import NotFoundError
from app.integrations.notifications.factory import get_notification_provider
from app.integrations.notifications.provider import PushMessage
from app.models.notification import (
    NOTIF_STATUS_SENT,
    NOTIF_TYPE_SYSTEM,
    Device,
    Notification,
    NotificationPreference,
)
from app.schemas.notification import (
    DeviceOut,
    DeviceRegisterRequest,
    NotificationOut,
    NotificationPreferenceOut,
    NotificationPreferenceUpdate,
    TestNotificationRequest,
    JobInfoOut,
    SchedulerHealthOut,
    TriggerJobOut,
)

router = APIRouter()


# ---------- Devices ----------


@router.post(
    "/devices",
    response_model=DeviceOut,
    status_code=status.HTTP_201_CREATED,
)
async def register_device(
    payload: DeviceRegisterRequest,
    session: SessionDep,
    user_id: CurrentUserId,
) -> DeviceOut:
    """Register (or update) a device for push notifications."""
    # Upsert by fcm_token
    stmt = select(Device).where(Device.fcm_token == payload.fcm_token)
    existing = (await session.execute(stmt)).scalar_one_or_none()

    now = datetime.now(UTC)
    if existing:
        existing.user_id = user_id
        existing.platform = payload.platform
        existing.device_model = payload.device_model
        existing.os_version = payload.os_version
        existing.app_version = payload.app_version
        existing.last_seen_at = now
        await session.commit()
        await session.refresh(existing)
        return DeviceOut.model_validate(existing)

    device = Device(
        user_id=user_id,
        fcm_token=payload.fcm_token,
        platform=payload.platform,
        device_model=payload.device_model,
        os_version=payload.os_version,
        app_version=payload.app_version,
        last_seen_at=now,
    )
    session.add(device)
    await session.commit()
    await session.refresh(device)
    return DeviceOut.model_validate(device)


@router.get("/devices", response_model=list[DeviceOut])
async def list_devices(
    session: SessionDep, user_id: CurrentUserId
) -> list[DeviceOut]:
    stmt = select(Device).where(Device.user_id == user_id)
    rows = (await session.execute(stmt)).scalars().all()
    return [DeviceOut.model_validate(d) for d in rows]


@router.delete("/devices/{device_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unregister_device(
    device_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> Response:
    stmt = select(Device).where(
        Device.id == device_id, Device.user_id == user_id
    )
    device = (await session.execute(stmt)).scalar_one_or_none()
    if not device:
        raise NotFoundError("Device not found.")
    await session.delete(device)
    await session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ---------- Notifications ----------


@router.get("", response_model=list[NotificationOut])
async def list_notifications(
    session: SessionDep,
    user_id: CurrentUserId,
    limit: int = 50,
) -> list[NotificationOut]:
    stmt = (
        select(Notification)
        .where(Notification.user_id == user_id)
        .order_by(Notification.created_at.desc())
        .limit(limit)
    )
    rows = (await session.execute(stmt)).scalars().all()
    return [NotificationOut.model_validate(n) for n in rows]


@router.post("/{notification_id}/read", response_model=NotificationOut)
async def mark_as_read(
    notification_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> NotificationOut:
    stmt = select(Notification).where(
        Notification.id == notification_id,
        Notification.user_id == user_id,
    )
    notif = (await session.execute(stmt)).scalar_one_or_none()
    if not notif:
        raise NotFoundError("Notification not found.")
    notif.read_at = datetime.now(UTC)
    await session.commit()
    await session.refresh(notif)
    return NotificationOut.model_validate(notif)


@router.post("/test", response_model=NotificationOut)
async def send_test_notification(
    payload: TestNotificationRequest,
    session: SessionDep,
    user_id: CurrentUserId,
) -> NotificationOut:
    """Send a test notification to the current user's devices."""
    provider = get_notification_provider()

    # Get user's devices
    stmt = select(Device).where(
        Device.user_id == user_id, Device.notifications_enabled.is_(True)
    )
    devices = (await session.execute(stmt)).scalars().all()

    # Create notification record
    notif = Notification(
        user_id=user_id,
        type=NOTIF_TYPE_SYSTEM,
        title=payload.title,
        body=payload.body,
        status=NOTIF_STATUS_SENT,
        sent_at=datetime.now(UTC),
    )
    session.add(notif)
    await session.flush()

    # Send to each device
    for device in devices:
        try:
            result = await provider.send(
                PushMessage(
                    token=device.fcm_token,
                    title=payload.title,
                    body=payload.body,
                    deep_link="/notifications",
                    data={"type": NOTIF_TYPE_SYSTEM},
                )
            )
            if result.success and result.message_id:
                notif.fcm_message_id = result.message_id
        except Exception:
            pass

    await session.commit()
    await session.refresh(notif)
    return NotificationOut.model_validate(notif)


# ---------- Preferences ----------


@router.get("/preferences", response_model=NotificationPreferenceOut)
async def get_preferences(
    session: SessionDep, user_id: CurrentUserId
) -> NotificationPreferenceOut:
    stmt = select(NotificationPreference).where(
        NotificationPreference.user_id == user_id
    )
    prefs = (await session.execute(stmt)).scalar_one_or_none()
    if not prefs:
        # Create default
        prefs = NotificationPreference(user_id=user_id)
        session.add(prefs)
        await session.commit()
        await session.refresh(prefs)
    return NotificationPreferenceOut.model_validate(prefs)


@router.patch("/preferences", response_model=NotificationPreferenceOut)
async def update_preferences(
    payload: NotificationPreferenceUpdate,
    session: SessionDep,
    user_id: CurrentUserId,
) -> NotificationPreferenceOut:
    stmt = select(NotificationPreference).where(
        NotificationPreference.user_id == user_id
    )
    prefs = (await session.execute(stmt)).scalar_one_or_none()
    if not prefs:
        prefs = NotificationPreference(user_id=user_id)
        session.add(prefs)
        await session.flush()

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(prefs, field, value)

    await session.commit()
    await session.refresh(prefs)
    return NotificationPreferenceOut.model_validate(prefs)


# ---------------------------------------------------------------------------
# Admin — scheduler monitoring + manual trigger (12B.6)
# ---------------------------------------------------------------------------
from app.services.notification.scheduler import get_scheduler  # noqa: E402


@router.get("/admin/health", response_model=SchedulerHealthOut)
async def admin_scheduler_health(
    _admin: AdminUser,
) -> SchedulerHealthOut:
    """Return scheduler status + list of registered jobs."""
    sched = get_scheduler()
    provider = get_notification_provider()

    if sched is None:
        return SchedulerHealthOut(
            running=False,
            job_count=0,
            provider=getattr(provider, "name", "unknown"),
            jobs=[],
        )

    jobs: list[JobInfoOut] = []
    for j in sched.get_jobs():
        nrt = getattr(j, "next_run_time", None)
        jobs.append(
            JobInfoOut(
                id=j.id,
                name=j.name or j.id,
                trigger=str(j.trigger),
                next_run_time=nrt.isoformat() if nrt else None,
            )
        )

    return SchedulerHealthOut(
        running=sched.running,
        job_count=len(jobs),
        provider=getattr(provider, "name", "unknown"),
        jobs=jobs,
    )


@router.post("/admin/trigger-job/{job_id}", response_model=TriggerJobOut)
async def admin_trigger_job(
    job_id: str,
    session: SessionDep,
    _admin: AdminUser,
) -> TriggerJobOut:
    """Manually trigger a notification job (admin debug)."""
    from app.services.notification import jobs as jobs_module

    job_map = {
        "notif_scan_upcoming_sessions": jobs_module.job_scan_upcoming_sessions,
        "notif_scan_exam_countdown": jobs_module.job_scan_exam_countdown,
        "notif_scan_streaks": jobs_module.job_scan_streaks,
        "notif_scan_inactivity": jobs_module.job_scan_inactivity,
        "notif_scan_subscriptions": jobs_module.job_scan_subscriptions,
    }

    job_fn = job_map.get(job_id)
    if job_fn is None:
        raise NotFoundError(
            f"Unknown job: {job_id}. "
            f"Available: {sorted(job_map.keys())}"
        )

    try:
        processed = await job_fn(session)
        await session.commit()
    except Exception as exc:  # noqa: BLE001
        await session.rollback()
        raise

    return TriggerJobOut(
        job_id=job_id,
        processed=processed,
        message=f"Job {job_id} processed {processed} user(s).",
    )
