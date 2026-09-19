"""
Pydantic 2.13+ does not coerce a raw uuid.UUID into a `str`-typed field
via model_validate(from_attributes=True) — every `XOut.model_validate
(orm_object)` call across this codebase for a schema with an id or
foreign-key field was silently broken until a real end-to-end HTTP
test (Phase 17) caught it on GET /users/me. Every prior phase's
service-level test called the service directly and asserted on the
returned ORM object or a hand-built dict, never on the actual JSON a
client would receive — this is exactly the gap a full HTTP test
closes that no amount of service-layer testing can.

`orm_to_dict` converts every UUID-typed column on a SQLAlchemy model
instance to its string form before Pydantic ever sees it, so response
schemas can keep declaring id/foreign-key fields as plain `str`
(matching what actually goes over the wire) without every router
needing its own str(...) conversions.
"""
import uuid


def orm_to_dict(instance) -> dict:
    result = {}
    for column in instance.__table__.columns:
        value = getattr(instance, column.name)
        result[column.name] = str(value) if isinstance(value, uuid.UUID) else value
    return result
