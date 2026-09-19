"""
Dev-only seed: gives the planner (Phase 7) real Course/Topic rows to
generate plans from, instead of every subject falling back to "General
review". Run with: python -m scripts.seed_catalog
"""
import asyncio

from api.core.db import async_session_factory
from api.modules.catalog.models import Course, Subject, Topic

SEED = {
    ("Mathematics", "GCE", "Advanced Level"): [
        "Algebra", "Trigonometry", "Differentiation", "Integration",
        "Differential Equations", "Vectors", "Statistics",
    ],
    ("Physics", "GCE", "Advanced Level"): [
        "Mechanics", "Waves", "Electricity", "Fields", "Thermodynamics", "Quantum Physics",
    ],
    ("Mathématiques", "Baccalauréat", "Terminale"): [
        "Suites numériques", "Fonctions", "Probabilités", "Géométrie dans l'espace",
    ],
}


async def seed():
    async with async_session_factory() as db:
        for (name, system, level), topic_titles in SEED.items():
            subject = Subject(name=name, education_system=system, level=level)
            db.add(subject)
            await db.flush()

            course = Course(subject_id=subject.id, title=f"{name} — {level}", outline={})
            db.add(course)
            await db.flush()

            for i, title in enumerate(topic_titles):
                db.add(Topic(course_id=course.id, title=title, order_index=i))

        await db.commit()
        print(f"Seeded {len(SEED)} subjects with courses and topics.")


if __name__ == "__main__":
    asyncio.run(seed())
