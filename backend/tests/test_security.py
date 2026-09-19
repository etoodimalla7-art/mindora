"""Phase 17's security hardening, tested at the real HTTP layer since
rate limiting and middleware are wiring-level concerns invisible to
service-layer tests."""


def test_security_headers_present(client):
    response = client.get("/health")
    assert response.headers.get("x-content-type-options") == "nosniff"
    assert response.headers.get("x-frame-options") == "DENY"


def test_rate_limit_triggers_and_uses_our_envelope(client):
    statuses = []
    for i in range(7):
        r = client.post("/api/v1/auth/register", json={"email": f"rl-{i}@test.com", "password": "supersecret1"})
        statuses.append(r.status_code)
    assert 429 in statuses, f"expected a 429 among {statuses}"
    first_429 = statuses.index(429)
    assert all(s == 200 for s in statuses[:first_429]), "every request before the limit trips should succeed"

    r = client.post("/api/v1/auth/register", json={"email": "over-limit@test.com", "password": "supersecret1"})
    assert r.status_code == 429
    body = r.json()
    assert body["error"]["code"] == "rate_limited"


def test_admin_gate_blocks_non_admin(registered_user, client):
    response = client.get("/api/v1/admin/documents/queue", headers=registered_user["headers"])
    assert response.status_code == 403
    assert response.json()["error"]["code"] == "forbidden"


def test_admin_gate_allows_admin(admin_user, client):
    response = client.get("/api/v1/admin/documents/queue", headers=admin_user["headers"])
    assert response.status_code == 200


def test_startup_check_rejects_placeholder_secret_outside_debug():
    from types import SimpleNamespace
    from api.core.startup_checks import check_production_safety

    check_production_safety(SimpleNamespace(debug=True, secret_key="change-me-to-a-long-random-string"))  # ok

    try:
        check_production_safety(SimpleNamespace(debug=False, secret_key="change-me-to-a-long-random-string"))
        assert False, "should have raised"
    except RuntimeError:
        pass
