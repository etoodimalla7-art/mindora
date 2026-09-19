"""
Section 56: rate limiting on auth and upload endpoints. Defined here
(not in main.py) so route modules can import `limiter` without a
circular import back to the app factory.

The exact numbers below are reasonable starting defaults, not
contractually final — same "adjustable without a business decision"
spirit as the placeholder subscription pricing in Phase 15. What
matters architecturally is that they're centralized here, not
scattered as magic numbers across route decorators.
"""
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

AUTH_WRITE_LIMIT = "5/minute"       # register, password reset request
LOGIN_LIMIT = "10/minute"           # login attempts — higher than register, still bounded
UPLOAD_LIMIT = "10/minute"          # document upload
