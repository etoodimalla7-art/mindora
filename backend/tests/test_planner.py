"""Study planner: exam-mode and subject-mode generation, plus
reschedule, over real HTTP."""
from datetime import date, timedelta


def test_exam_plan_creates_correct_session_count(registered_user, client):
    headers = registered_user["headers"]
    exam_date = (date.today() + timedelta(days=6)).isoformat()
    response = client.post("/api/v1/planner/exam-plan", headers=headers, json={
        "target_exam_name": "GCE Advanced Level",
        "subject_names": ["Mathematics", "Physics"],
        "exam_date": exam_date,
    })
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["session_count"] == 6

    sessions = client.get(f"/api/v1/planner/plans/{data['id']}/sessions", headers=headers)
    assert len(sessions.json()["data"]) == 6


def test_exam_plan_rejects_past_date(registered_user, client):
    headers = registered_user["headers"]
    past_date = (date.today() - timedelta(days=1)).isoformat()
    response = client.post("/api/v1/planner/exam-plan", headers=headers, json={
        "target_exam_name": "X", "subject_names": ["Mathematics"], "exam_date": past_date,
    })
    assert response.status_code == 422


def test_subject_plan_with_explicit_topic(registered_user, client):
    headers = registered_user["headers"]
    response = client.post("/api/v1/planner/subject-plan", headers=headers, json={
        "subject_name": "Mathematics", "topic_title": "Differential Equations", "duration_days": 4,
    })
    assert response.status_code == 200
    assert response.json()["data"]["session_count"] == 4


def test_reschedule_endpoint_works(registered_user, client):
    headers = registered_user["headers"]
    exam_date = (date.today() + timedelta(days=5)).isoformat()
    plan = client.post("/api/v1/planner/exam-plan", headers=headers, json={
        "target_exam_name": "X", "subject_names": ["Mathematics"], "exam_date": exam_date,
    }).json()["data"]

    response = client.patch(f"/api/v1/planner/plans/{plan['id']}/reschedule", headers=headers)
    assert response.status_code == 200
    assert "rescheduled_count" in response.json()["data"]
