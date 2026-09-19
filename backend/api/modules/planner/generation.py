"""
Sections 31-34: exam-mode and subject-mode plan generation. Pure
function, no I/O — round-robins across subjects day by day and cycles
each subject's topics, so it's fully unit-testable without a database.
The service layer resolves subject/topic names to catalog IDs and hands
plain dicts in here; this function only knows about strings and counts.
"""

FALLBACK_TOPIC = {"title": "General review", "id": None}


def build_session_plan(subjects_topics: dict[str, list[dict]], total_days: int) -> list[dict]:
    """
    subjects_topics: {subject_name: [{"title": ..., "id": ...}, ...]}.
    An empty topic list for a subject falls back to FALLBACK_TOPIC
    rather than failing generation — section 33 (university mode without
    a course outline yet) is exactly this case.

    Returns a list of {day_offset, subject_name, topic_title, topic_id}
    dicts, one per day, cycling subjects round-robin and each subject's
    topics in order (adaptive re-weighting toward weak topics is a
    Phase-34 follow-up once quiz/performance data exists).
    """
    subject_names = list(subjects_topics.keys())
    if not subject_names or total_days < 1:
        return []

    topics_by_subject = {name: (subjects_topics[name] or [FALLBACK_TOPIC]) for name in subject_names}
    cursor = {name: 0 for name in subject_names}

    plan = []
    for day in range(total_days):
        subject_name = subject_names[day % len(subject_names)]
        topics = topics_by_subject[subject_name]
        topic = topics[cursor[subject_name] % len(topics)]
        plan.append({
            "day_offset": day,
            "subject_name": subject_name,
            "topic_title": topic["title"],
            "topic_id": topic["id"],
        })
        cursor[subject_name] += 1
    return plan
