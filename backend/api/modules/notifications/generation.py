"""
Section 47: notification content generation — pure functions deciding
WHAT a reminder says and WHETHER "now" is a valid time to show one,
given already-fetched state. Real push delivery (FCM/APNs device
tokens) isn't built — this module produces the rows an in-app
notification center reads; wiring a push provider behind the same rows
is a later addition, same Replaceability philosophy as every other
provider interface in this codebase.
"""
from datetime import datetime


def is_within_quiet_hours(check_time: datetime, quiet_start_hour: int, quiet_end_hour: int) -> bool:
    """Quiet hours can wrap midnight (e.g. 22 -> 7 means 10pm-7am).
    Equal start/end means a zero-width window -> never quiet."""
    if quiet_start_hour == quiet_end_hour:
        return False
    hour = check_time.hour
    if quiet_start_hour < quiet_end_hour:
        return quiet_start_hour <= hour < quiet_end_hour
    return hour >= quiet_start_hour or hour < quiet_end_hour


def build_upcoming_session_reminder(subject_name: str, topic_title: str, minutes_until: int) -> dict:
    return {
        "type": "session_upcoming",
        "title": "Study session starting soon",
        "body": f"Your {subject_name} session on {topic_title} starts in {minutes_until} minutes.",
    }


def build_missed_session_reminder(subject_name: str, topic_title: str) -> dict:
    return {
        "type": "session_missed",
        "title": "You missed a session",
        "body": f"You missed your {subject_name} session on {topic_title}. Want to reorganize your plan?",
    }


def build_exam_countdown_reminder(exam_name: str, days_remaining: int, weakest_subject: str | None) -> dict:
    body = f"Your {exam_name} is {days_remaining} day{'s' if days_remaining != 1 else ''} away."
    if weakest_subject:
        body += f" Your weakest subject right now is {weakest_subject}."
    return {"type": "exam_countdown", "title": "Exam countdown", "body": body}
