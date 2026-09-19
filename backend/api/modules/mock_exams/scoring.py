"""
Sections 40-42: aggregates per-subject quiz results into an overall
mock-exam score plus a per-subject breakdown. Pure function so the
scoring math is verifiable without a database or any quiz-generation
machinery involved.
"""


def score_sections(sections_correct_counts: dict[str, tuple[int, int]]) -> tuple[float, dict[str, float]]:
    """
    sections_correct_counts: {subject_name: (correct, total)}.
    Returns (overall_score, {subject_name: section_score}) as
    percentages rounded to 1 decimal. A subject with 0 questions scores
    0.0 rather than raising ZeroDivisionError, and an empty exam scores
    0.0 overall rather than crashing.
    """
    section_scores: dict[str, float] = {}
    total_correct = 0
    total_questions = 0

    for subject, (correct, total) in sections_correct_counts.items():
        section_scores[subject] = round((correct / total) * 100, 1) if total else 0.0
        total_correct += correct
        total_questions += total

    overall = round((total_correct / total_questions) * 100, 1) if total_questions else 0.0
    return overall, section_scores
