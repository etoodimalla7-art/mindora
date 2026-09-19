"""Notifications preferences and credits/subscriptions over real HTTP."""


def test_notification_preferences_default_and_update(registered_user, client):
    headers = registered_user["headers"]
    prefs = client.get("/api/v1/notifications/preferences", headers=headers)
    assert prefs.status_code == 200
    assert prefs.json()["data"]["enabled"] is True

    updated = client.put("/api/v1/notifications/preferences", headers=headers, json={"enabled": False})
    assert updated.status_code == 200
    assert updated.json()["data"]["enabled"] is False


def test_notifications_list_does_not_crash_with_no_activity(registered_user, client):
    response = client.get("/api/v1/notifications", headers=registered_user["headers"])
    assert response.status_code == 200
    assert response.json()["data"] == []


def test_new_user_has_three_free_credits(registered_user, client):
    response = client.get("/api/v1/credits/balance", headers=registered_user["headers"])
    assert response.status_code == 200
    assert response.json()["data"]["balance"] == 3


def test_subscription_plans_and_subscribe(registered_user, client):
    headers = registered_user["headers"]
    plans = client.get("/api/v1/subscriptions/plans", headers=headers)
    assert plans.status_code == 200
    assert len(plans.json()["data"]) == 2

    subscribe = client.post("/api/v1/subscriptions/subscribe", headers=headers, json={"plan_code": "monthly"})
    assert subscribe.status_code == 200
    assert subscribe.json()["data"]["status"] == "active"

    cancel = client.post("/api/v1/subscriptions/cancel", headers=headers)
    assert cancel.status_code == 200
    assert cancel.json()["data"]["status"] == "canceled"
