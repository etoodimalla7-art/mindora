"""Decorator to automatically audit admin actions."""
from __future__ import annotations

import functools
import logging
import uuid
from datetime import datetime, timezone
from typing import Any, Awaitable, Callable

logger = logging.getLogger(__name__)


def _extract_arg(
    name: str, args: tuple, kwargs: dict, varnames: tuple[str, ...]
) -> Any:
    """Extract a named argument from kwargs or positional args.

    Note: `args` does NOT include `self` (Python already stripped it).
    `varnames` includes `self` at index 0.
    """
    if name in kwargs:
        return kwargs[name]
    if name in varnames:
        idx_in_varnames = varnames.index(name)
        # idx_in_args = idx_in_varnames - 1 (because self is at 0)
        idx_in_args = idx_in_varnames - 1
        if 0 <= idx_in_args < len(args):
            return args[idx_in_args]
    return None


def audit_action(
    action: str,
    resource_type: str | None = None,
    resource_id_arg: str | None = None,
    admin_id_arg: str = "admin_id",
    admin_email_arg: str | None = "admin_email",
):
    """Wrap an async method to log it to audit_logs."""
    def decorator(fn: Callable[..., Awaitable[Any]]):
        @functools.wraps(fn)
        async def wrapper(self, *args, **kwargs):
            varnames = fn.__code__.co_varnames

            admin_id = _extract_arg(admin_id_arg, args, kwargs, varnames)
            admin_email = (
                _extract_arg(admin_email_arg, args, kwargs, varnames)
                if admin_email_arg else None
            )
            resource_id = (
                _extract_arg(resource_id_arg, args, kwargs, varnames)
                if resource_id_arg else None
            )

            try:
                result = await fn(self, *args, **kwargs)
                await _write_audit(
                    self.session,
                    admin_id=admin_id,
                    admin_email=admin_email,
                    action=action,
                    resource_type=resource_type,
                    resource_id=resource_id,
                    result="success",
                )
                return result
            except Exception as exc:
                await _write_audit(
                    self.session,
                    admin_id=admin_id,
                    admin_email=admin_email,
                    action=action,
                    resource_type=resource_type,
                    resource_id=resource_id,
                    result="error",
                    error=f"{type(exc).__name__}: {exc}",
                )
                raise

        return wrapper
    return decorator


async def _write_audit(
    session,
    *,
    admin_id,
    admin_email,
    action,
    resource_type,
    resource_id,
    result,
    error=None,
):
    """Write audit log AND commit it immediately."""
    try:
        from app.models.audit_log import AuditLog
        entry = AuditLog(
            admin_id=admin_id if admin_id else None,
            admin_email=admin_email,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id if resource_id else None,
            result=result,
            error=error,
            created_at=datetime.now(timezone.utc),
        )
        session.add(entry)
        await session.commit()
        logger.info(
            "audit_logged action=%s admin=%s resource=%s result=%s",
            action, admin_id, resource_id, result,
        )
    except Exception as exc:
        logger.exception("audit_write_failed action=%s error=%s", action, exc)
        try:
            await session.rollback()
        except Exception:
            pass
