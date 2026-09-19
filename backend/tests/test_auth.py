"""Real HTTP tests of the auth flow — see Phase 17's finding that only
a real HTTP call (real password hashing, real Pydantic serialization)
catches bugs service-level tests miss."""


def test_register_and_login(client):
    email = "auth-flow@test.com"
    reg = client.post("/api/v1/auth/register", json={"email": email, "password": "supersecret1"})
    assert reg.status_code == 200
    assert reg.json()["data"]["access_token"]

    login = client.post("/api/v1/auth/login", json={"email": email, "password": "supersecret1"})
    assert login.status_code == 200
    assert login.json()["data"]["access_token"]


def test_login_wrong_password_rejected(client):
    email = "wrongpass@test.com"
    client.post("/api/v1/auth/register", json={"email": email, "password": "supersecret1"})
    login = client.post("/api/v1/auth/login", json={"email": email, "password": "wrongpassword"})
    assert login.status_code == 401


def test_duplicate_registration_rejected(client):
    email = "dup@test.com"
    client.post("/api/v1/auth/register", json={"email": email, "password": "supersecret1"})
    second = client.post("/api/v1/auth/register", json={"email": email, "password": "anotherpass1"})
    assert second.status_code == 422


def test_get_me_returns_correct_shape(registered_user, client):
    # The exact endpoint Phase 17 found broken by the UUID-serialization bug.
    response = client.get("/api/v1/users/me", headers=registered_user["headers"])
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["email"] == registered_user["email"]
    assert isinstance(data["id"], str)
    assert len(data["id"]) == 36  # a real UUID string, not a crash


def test_forgot_password_same_response_regardless_of_existence(client):
    exists = client.post("/api/v1/auth/password/forgot", json={"email": "nonexistent@test.com"})
    assert exists.status_code == 200
    assert "reset link" in exists.json()["data"]["message"].lower()
