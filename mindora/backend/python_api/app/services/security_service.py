"""Security & Monitoring service (Phase 7.1)."""
from __future__ import annotations

import logging
import time
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.models.security import (
    ALERT_SEVERITY_MEDIUM,
    ALERT_TYPE_FAILED_LOGIN,
    ALERT_TYPE_MANUAL,
    ALERT_TYPES,
    ALERT_SEVERITIES,
    AdminLoginHistory,
    SecurityAlert,
)
from app.models.session import Session
from app.models.support import SupportTicket
from app.models.user import User
from app.schemas.security import (
    AlertAckOut,
    AlertCreate,
    AlertListOut,
    LoginHistoryListOut,
    LoginHistoryRow,
    SecurityAlertOut,
    ServiceStatus,
    SystemHealthOut,
    SystemMetricsOut,
)

logger = logging.getLogger(__name__)

# Process start time (approximation uptime)
_START_TIME = time.time()


class SecurityService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ---------- System Health ----------

    async def health(self) -> SystemHealthOut:
        services: list[ServiceStatus] = []

        # Database
        try:
            t0 = time.perf_counter()
            await self.session.execute(text("SELECT 1"))
            latency = (time.perf_counter() - t0) * 1000
            services.append(
                ServiceStatus(name="database", status="ok", latency_ms=round(latency, 2))
            )
        except Exception as e:
            services.append(ServiceStatus(name="database", status="down", detail=str(e)))

        # Redis (best effort via ping — optional)
        try:
            from app.db.redis import get_redis  # type: ignore
            r = await get_redis()
            t0 = time.perf_counter()
            await r.ping()
            latency = (time.perf_counter() - t0) * 1000
            services.append(
                ServiceStatus(name="redis", status="ok", latency_ms=round(latency, 2))
            )
        except Exception:
            services.append(
                ServiceStatus(name="redis", status="degraded", detail="not configured")
            )

        # Storage (BYTEA in DB → rely on DB)
        services.append(ServiceStatus(name="storage", status="ok", detail="db-backed"))

        # Overall
        statuses = {s.status for s in services}
        if "down" in statuses:
            overall = "down"
        elif "degraded" in statuses:
            overall = "degraded"
        else:
            overall = "ok"

        from app.core.config import settings  # local import to avoid cycle

        return SystemHealthOut(
            overall=overall,
            timestamp=datetime.now(timezone.utc),
            services=services,
            uptime_seconds=round(time.time() - _START_TIME, 1),
            version=getattr(settings, "APP_VERSION", "0.1.0"),
            env=getattr(settings, "ENV", "development"),
        )

    # ---------- Metrics ----------

    async def metrics(self) -> SystemMetricsOut:
        now = datetime.now(timezone.utc)
        day_ago = now - timedelta(days=1)

        total_users = (
            await self.session.execute(select(func.count(User.id)))
        ).scalar_one()

        active_sessions_24h = (
            await self.session.execute(
                select(func.count(func.distinct(Session.user_id))).where(
                    Session.created_at >= day_ago
                )
            )
        ).scalar_one()

        failed_logins_24h = (
            await self.session.execute(
                select(func.count(AdminLoginHistory.id)).where(
                    AdminLoginHistory.success.is_(False),
                    AdminLoginHistory.created_at >= day_ago,
                )
            )
        ).scalar_one()

        unack_alerts = (
            await self.session.execute(
                select(func.count(SecurityAlert.id)).where(
                    SecurityAlert.acknowledged.is_(False)
                )
            )
        ).scalar_one()

        # DB size (postgres only)
        db_size_mb = None
        try:
            r = await self.session.execute(
                text("SELECT pg_database_size(current_database()) / 1024.0 / 1024.0")
            )
            db_size_mb = round(float(r.scalar_one()), 2)
        except Exception:
            pass

        return SystemMetricsOut(
            total_users=total_users,
            active_sessions_24h=active_sessions_24h,
            requests_per_minute=0,  # TODO: instrument with middleware in Phase 7.3
            failed_logins_24h=failed_logins_24h,
            unacknowledged_alerts=unack_alerts,
            database_size_mb=db_size_mb,
            updated_at=now,
        )

    # ---------- Login History ----------

    async def list_login_history(
        self,
        success: bool | None = None,
        email: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> LoginHistoryListOut:
        stmt = select(AdminLoginHistory)
        if success is not None:
            stmt = stmt.where(AdminLoginHistory.success.is_(success))
        if email:
            stmt = stmt.where(AdminLoginHistory.email.ilike(f"%{email}%"))

        count = (
            await self.session.execute(
                select(func.count()).select_from(stmt.subquery())
            )
        ).scalar_one()

        stmt = (
            stmt.order_by(AdminLoginHistory.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        rows = (await self.session.execute(stmt)).scalars().all()

        items = [
            LoginHistoryRow(
                id=r.id,
                user_id=r.user_id,
                email=r.email,
                ip=r.ip,
                user_agent=r.user_agent,
                success=r.success,
                failure_reason=r.failure_reason,
                created_at=r.created_at,
            )
            for r in rows
        ]
        return LoginHistoryListOut(items=items, total=count, limit=limit, offset=offset)

    async def record_login(
        self,
        user_id: uuid.UUID | None,
        email: str,
        ip: str | None,
        user_agent: str | None,
        success: bool,
        failure_reason: str | None = None,
    ) -> None:
        """Record a login attempt + auto-create alert on failure streak."""
        row = AdminLoginHistory(
            user_id=user_id,
            email=email,
            ip=ip,
            user_agent=user_agent,
            success=success,
            failure_reason=failure_reason,
        )
        self.session.add(row)
        await self.session.commit()

        # Auto-alert: 5+ failures in last 10 min for same email
        if not success:
            ten_min_ago = datetime.now(timezone.utc) - timedelta(minutes=10)
            fail_count = (
                await self.session.execute(
                    select(func.count(AdminLoginHistory.id)).where(
                        AdminLoginHistory.email == email,
                        AdminLoginHistory.success.is_(False),
                        AdminLoginHistory.created_at >= ten_min_ago,
                    )
                )
            ).scalar_one()
            if fail_count >= 5:
                # Check we didn't already create one recently for same email
                existing = (
                    await self.session.execute(
                        select(func.count(SecurityAlert.id)).where(
                            SecurityAlert.type == ALERT_TYPE_FAILED_LOGIN,
                            SecurityAlert.created_at >= ten_min_ago,
                            SecurityAlert.message.contains(email),
                        )
                    )
                ).scalar_one()
                if existing == 0:
                    alert = SecurityAlert(
                        type=ALERT_TYPE_FAILED_LOGIN,
                        severity="high",
                        message=f"Multiple failed logins ({fail_count}) for {email} within 10 min",
                        metadata_json={"email": email, "ip": ip, "count": fail_count},
                    )
                    self.session.add(alert)
                    await self.session.commit()

    # ---------- Alerts ----------

    async def list_alerts(
        self,
        acknowledged: bool | None = None,
        severity: str | None = None,
        alert_type: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> AlertListOut:
        stmt = select(SecurityAlert)
        if acknowledged is not None:
            stmt = stmt.where(SecurityAlert.acknowledged.is_(acknowledged))
        if severity and severity in ALERT_SEVERITIES:
            stmt = stmt.where(SecurityAlert.severity == severity)
        if alert_type and alert_type in ALERT_TYPES:
            stmt = stmt.where(SecurityAlert.type == alert_type)

        total = (
            await self.session.execute(
                select(func.count()).select_from(stmt.subquery())
            )
        ).scalar_one()
        unack = (
            await self.session.execute(
                select(func.count(SecurityAlert.id)).where(
                    SecurityAlert.acknowledged.is_(False)
                )
            )
        ).scalar_one()

        stmt = (
            stmt.order_by(SecurityAlert.created_at.desc()).limit(limit).offset(offset)
        )
        rows = (await self.session.execute(stmt)).scalars().all()

        items = [
            SecurityAlertOut(
                id=r.id,
                type=r.type,
                severity=r.severity,
                message=r.message,
                metadata=r.metadata_json or {},
                acknowledged=r.acknowledged,
                acknowledged_by=r.acknowledged_by,
                acknowledged_at=r.acknowledged_at,
                created_at=r.created_at,
            )
            for r in rows
        ]
        return AlertListOut(items=items, total=total, unacknowledged=unack)

    async def create_alert(
        self, payload: AlertCreate, created_by: uuid.UUID | None = None
    ) -> SecurityAlertOut:
        alert = SecurityAlert(
            type=payload.type if payload.type in ALERT_TYPES else ALERT_TYPE_MANUAL,
            severity=payload.severity,
            message=payload.message,
            metadata_json=payload.metadata or {},
        )
        self.session.add(alert)
        await self.session.commit()
        await self.session.refresh(alert)

        return SecurityAlertOut(
            id=alert.id,
            type=alert.type,
            severity=alert.severity,
            message=alert.message,
            metadata=alert.metadata_json or {},
            acknowledged=alert.acknowledged,
            acknowledged_by=alert.acknowledged_by,
            acknowledged_at=alert.acknowledged_at,
            created_at=alert.created_at,
        )

    async def acknowledge_alert(
        self, alert_id: uuid.UUID, admin_id: uuid.UUID
    ) -> AlertAckOut:
        alert = (
            await self.session.execute(
                select(SecurityAlert).where(SecurityAlert.id == alert_id)
            )
        ).scalar_one_or_none()
        if not alert:
            raise NotFoundError("Alerte introuvable.")

        alert.acknowledged = True
        alert.acknowledged_by = admin_id
        alert.acknowledged_at = datetime.now(timezone.utc)
        await self.session.commit()

        return AlertAckOut(
            id=alert.id,
            acknowledged=alert.acknowledged,
            acknowledged_at=alert.acknowledged_at,
        )
