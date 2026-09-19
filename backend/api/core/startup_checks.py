"""
Section 56: refuse to start with an obviously unsafe configuration.
A pure function (takes a Settings-like object, raises or doesn't) so
it's testable without booting the actual app.
"""

_KNOWN_INSECURE_SECRETS = {"", "change-me-to-a-long-random-string"}


def check_production_safety(settings) -> None:
    """
    Raises RuntimeError if the app is configured to run outside debug
    mode with the placeholder SECRET_KEY still in place — signing JWTs
    with a secret anyone can read from this repository's own
    .env.example would make every access token forgeable.
    """
    if not settings.debug and settings.secret_key in _KNOWN_INSECURE_SECRETS:
        raise RuntimeError(
            "Refusing to start: SECRET_KEY is still the placeholder value from "
            ".env.example. Set a real, random secret before running outside debug mode."
        )
