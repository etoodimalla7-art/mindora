"""
SQLAlchemy's Uuid column type (used for every id/FK in this codebase —
see core/db.py's Base) requires actual `uuid.UUID` instances when
binding query parameters; a plain string raises a confusing
AttributeError deep in the SQL compiler. Every ID crossing the API
boundary (path params, `current_user.id` after `str()`, etc.) is a
string, so repositories convert at the query boundary via this helper
rather than trusting callers to remember.
"""
import uuid

from api.core.errors import ValidationFailedError


def to_uuid(value: str | uuid.UUID) -> uuid.UUID:
    if isinstance(value, uuid.UUID):
        return value
    try:
        return uuid.UUID(value)
    except (ValueError, AttributeError, TypeError) as exc:
        raise ValidationFailedError("That id doesn't look right.") from exc
