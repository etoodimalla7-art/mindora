"""
Dev-only seed script. Past papers normally reach the library via the
admin approval pipeline (Phase 16) — this exists so the browse/filter/
bookmark UI has real data to work against before that pipeline exists.

Run with:  python -m scripts.seed_past_papers
"""
import asyncio

from api.core.db import async_session_factory
from api.modules.catalog.models import Subject
from api.modules.past_papers.models import Examination, PastPaper

SEED_EXAMS = [
    ("Cameroon", "GCE", "GCE Ordinary Level"),
    ("Cameroon", "GCE", "GCE Advanced Level"),
    ("Cameroon", "Baccalauréat", "Baccalauréat"),
]

SEED_SUBJECTS = [
    ("Mathematics", "GCE", "Ordinary Level"),
    ("Physics", "GCE", "Advanced Level"),
    ("Mathématiques", "Baccalauréat", "Terminale"),
]

SEED_PAPERS = [
    # (exam_index, subject_index, level, year, session)
    (0, 0, "Ordinary Level", 2024, "June"),
    (0, 0, "Ordinary Level", 2023, "June"),
    (1, 1, "Advanced Level", 2025, "June"),
    (2, 2, "Terminale", 2024, None),
]


async def seed():
    async with async_session_factory() as db:
        exams = []
        for country, system, name in SEED_EXAMS:
            exam = Examination(country=country, system=system, name=name)
            db.add(exam)
            exams.append(exam)
        await db.flush()

        subjects = []
        for name, system, level in SEED_SUBJECTS:
            subject = Subject(name=name, education_system=system, level=level)
            db.add(subject)
            subjects.append(subject)
        await db.flush()

        for exam_idx, subject_idx, level, year, session in SEED_PAPERS:
            exam = exams[exam_idx]
            subject = subjects[subject_idx]
            db.add(PastPaper(
                examination_id=exam.id,
                subject_id=subject.id,
                title=f"{exam.name} {subject.name} {year}",
                level=level,
                year=year,
                session=session,
            ))
        await db.commit()
        print(f"Seeded {len(SEED_EXAMS)} examinations, {len(SEED_SUBJECTS)} subjects, {len(SEED_PAPERS)} past papers.")


if __name__ == "__main__":
    asyncio.run(seed())
