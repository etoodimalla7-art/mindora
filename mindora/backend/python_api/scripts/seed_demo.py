"""Idempotent demo & bootstrap seed script for MINDORA.

Run:
    python -m scripts.seed_demo
"""
from __future__ import annotations

import asyncio
from datetime import date, datetime, timedelta, timezone

from sqlalchemy import select

from app.core.security import hash_password
from app.db.session import AsyncSessionLocal
from app.models.ai_config import AIConfig, AIConfigVersion
from app.models.content import ContentString
from app.models.flashcard import Flashcard, FlashcardDeck
from app.models.paper import PAPER_STATUS_PUBLISHED, Paper
from app.models.plan import StudyPlan, StudySession
from app.models.progress import TopicProgress
from app.models.role import Role, UserRole
from app.models.study_group import StudyGroup, StudyGroupMember
from app.models.user import EducationProfile, User
from app.services.credit_service import CreditService


def _minimal_pdf(title: str) -> bytes:
    """Build a valid minimal single-page PDF file for testing downloads."""
    safe = title.replace("(", "[").replace(")", "]")
    stream = f"BT /F1 16 Tf 72 720 Td ({safe}) Tj ET".encode("latin-1", "replace")
    objs = [
        b"1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n",
        b"2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n",
        (
            b"3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
            b"/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj\n"
        ),
        (
            f"4 0 obj << /Length {len(stream)} >> stream\n".encode("ascii")
            + stream
            + b"\nendstream endobj\n"
        ),
        b"5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n",
    ]
    out = bytearray(b"%PDF-1.4\n")
    offsets = [0]
    for obj in objs:
        offsets.append(len(out))
        out.extend(obj)
    xref_pos = len(out)
    out.extend(f"xref\n0 {len(offsets)}\n".encode("ascii"))
    out.extend(b"0000000000 65535 f \n")
    for off in offsets[1:]:
        out.extend(f"{off:010d} 00000 n \n".encode("ascii"))
    out.extend(
        f"trailer << /Size {len(offsets)} /Root 1 0 R >>\nstartxref\n{xref_pos}\n%%EOF\n".encode(
            "ascii"
        )
    )
    return bytes(out)


CMS_DEFAULTS = [
    (
        "hero.headline",
        "general",
        "Ton tuteur académique IA pour réussir tes examens",
        "Your AI academic tutor built to master every exam",
        "Titre principal de l'accueil",
    ),
    (
        "hero.subheadline",
        "general",
        "GCE O/A-Level, BEPC, Probatoire, Baccalauréat, HND, BTS, Licence & Master — annales, flashcards SM-2, examens blancs corrigés et suivi de maîtrise.",
        "GCE O/A-Level, BEPC, Probatoire, Baccalauréat, HND, BTS, Bachelor & Master — past papers, SM-2 flashcards, graded mock exams, and mastery analytics.",
        "Sous-titre principal",
    ),
    (
        "tutor.welcome",
        "tutor",
        "Bonjour ! Quelle notion ou annale veux-tu travailler aujourd'hui ?",
        "Hello! Which topic or past paper would you like to master today?",
        "Message d'accueil du tuteur IA",
    ),
]

DEMO_PAPERS = [
    {
        "title": "Baccalauréat C — Mathématiques (Sujet Officiel 2024)",
        "subject": "Mathematics",
        "exam_system": "BAC",
        "exam_level": "Terminale",
        "exam_year": 2024,
        "language": "fr",
        "description": "Épreuve complète d'algèbre, nombres complexes, probabilités et analyse.",
        "file_name": "bac-c-maths-2024.pdf",
    },
    {
        "title": "GCE A-Level Physics Paper 2 (Cameroon GCE Board 2024)",
        "subject": "Physics",
        "exam_system": "GCE_A_LEVEL",
        "exam_level": "Upper Six",
        "exam_year": 2024,
        "language": "en",
        "description": "Mechanics, waves, electromagnetism, and modern physics structured questions.",
        "file_name": "gce-al-physics-2024.pdf",
    },
    {
        "title": "Probatoire D — Sciences de la Vie et de la Terre 2023",
        "subject": "Biology",
        "exam_system": "PROBATOIRE",
        "exam_level": "Première",
        "exam_year": 2023,
        "language": "fr",
        "description": "Biologie cellulaire, génétique mendélienne et physiologie humaine.",
        "file_name": "probatoire-d-svt-2023.pdf",
    },
    {
        "title": "GCE O-Level Chemistry Paper 1 & 2 (2023)",
        "subject": "Chemistry",
        "exam_system": "GCE_O_LEVEL",
        "exam_level": "Form 5",
        "exam_year": 2023,
        "language": "en",
        "description": "Atomic structure, stoichiometry, organic chemistry and titration practice.",
        "file_name": "gce-ol-chemistry-2023.pdf",
    },
]


async def seed_demo() -> None:
    async with AsyncSessionLocal() as session:
        # 1. Admin user
        admin = (
            await session.execute(select(User).where(User.email == "admin@mindora.dev"))
        ).scalar_one_or_none()
        if not admin:
            admin = User(
                email="admin@mindora.dev",
                hashed_password=hash_password("MindoraAdmin2026!"),
                full_name="MINDORA Super Admin",
                preferred_language="fr",
                country_code="CM",
                is_admin=True,
                is_active=True,
                is_verified=True,
            )
            session.add(admin)
            await session.flush()
            await CreditService(session).grant_signup_bonus(admin.id)

        # Assign super_admin RBAC role if exists
        super_role = (
            await session.execute(select(Role).where(Role.name == "super_admin"))
        ).scalar_one_or_none()
        if super_role:
            existing_ur = (
                await session.execute(
                    select(UserRole).where(
                        UserRole.user_id == admin.id,
                        UserRole.role_id == super_role.id,
                    )
                )
            ).scalar_one_or_none()
            if not existing_ur:
                session.add(
                    UserRole(
                        user_id=admin.id,
                        role_id=super_role.id,
                        granted_by=admin.id,
                    )
                )

        # 2. Student demo account
        student = (
            await session.execute(
                select(User).where(User.email == "student@mindora.dev")
            )
        ).scalar_one_or_none()
        if not student:
            student = User(
                email="student@mindora.dev",
                hashed_password=hash_password("MindoraStudent2026!"),
                full_name="Amina Ndi (Terminale C)",
                preferred_language="fr",
                country_code="CM",
                is_admin=False,
                is_active=True,
                is_verified=True,
            )
            session.add(student)
            await session.flush()
            await CreditService(session).grant_signup_bonus(student.id)

        # Education profile for student
        edu = (
            await session.execute(
                select(EducationProfile).where(EducationProfile.user_id == student.id)
            )
        ).scalar_one_or_none()
        if not edu:
            session.add(
                EducationProfile(
                    user_id=student.id,
                    education_system="BAC",
                    level="Terminale",
                    subjects=["Mathematics", "Physics", "Chemistry", "Biology"],
                    goals=["Obtenir la mention Très Bien au Bac C"],
                    target_exam_date=date.today() + timedelta(days=90),
                    study_preferences={"daily_minutes": 60, "onboarding_completed": True},
                )
            )

        # 3. Sample study plan + sessions + progress for student
        existing_plan = (
            await session.execute(
                select(StudyPlan).where(StudyPlan.user_id == student.id).limit(1)
            )
        ).scalar_one_or_none()
        if not existing_plan:
            plan = StudyPlan(
                user_id=student.id,
                title="Sprint Baccalauréat C — Mathématiques & Physique",
                plan_type="exam",
                subject="Mathematics",
                exam_system="BAC",
                exam_level="Terminale",
                exam_name="Baccalauréat C 2026",
                start_date=date.today(),
                target_date=date.today() + timedelta(days=90),
                daily_minutes=60,
                is_active=True,
            )
            session.add(plan)
            await session.flush()
            now = datetime.now(timezone.utc)
            session.add_all(
                [
                    StudySession(
                        plan_id=plan.id,
                        user_id=student.id,
                        title="Nombres complexes & Transformations géométriques",
                        subject="Mathematics",
                        topic="Nombres complexes",
                        objective="Maîtriser la forme exponentielle et les lieux géométriques",
                        scheduled_for=now - timedelta(days=1),
                        duration_minutes=45,
                        status="completed",
                        completed_at=now - timedelta(days=1),
                    ),
                    StudySession(
                        plan_id=plan.id,
                        user_id=student.id,
                        title="Ondes mécaniques progressives & Diffraction",
                        subject="Physics",
                        topic="Ondes et Optique",
                        objective="Résoudre 3 exercices types d'annales GCE / Bac",
                        scheduled_for=now + timedelta(hours=3),
                        duration_minutes=50,
                        status="scheduled",
                    ),
                ]
            )

        existing_prog = (
            await session.execute(
                select(TopicProgress).where(TopicProgress.user_id == student.id).limit(1)
            )
        ).scalar_one_or_none()
        if not existing_prog:
            session.add_all(
                [
                    TopicProgress(
                        user_id=student.id,
                        subject="Mathematics",
                        topic="Nombres complexes",
                        mastery=0.78,
                        confidence=0.80,
                        questions_seen=20,
                        questions_correct=16,
                        minutes_studied=90,
                    ),
                    TopicProgress(
                        user_id=student.id,
                        subject="Physics",
                        topic="Cinématique & Dynamique",
                        mastery=0.45,
                        confidence=0.50,
                        questions_seen=12,
                        questions_correct=6,
                        minutes_studied=45,
                    ),
                ]
            )

        # 4. Past Papers
        for p in DEMO_PAPERS:
            exists = (
                await session.execute(select(Paper).where(Paper.title == p["title"]))
            ).scalar_one_or_none()
            if not exists:
                pdf_bytes = _minimal_pdf(p["title"])
                session.add(
                    Paper(
                        uploader_id=admin.id,
                        title=p["title"],
                        description=p["description"],
                        subject=p["subject"],
                        exam_system=p["exam_system"],
                        exam_level=p["exam_level"],
                        exam_year=p["exam_year"],
                        language=p["language"],
                        file_data=pdf_bytes,
                        file_name=p["file_name"],
                        file_size=len(pdf_bytes),
                        mime_type="application/pdf",
                        status=PAPER_STATUS_PUBLISHED,
                    )
                )

        # 5. Flashcard Deck
        deck = (
            await session.execute(
                select(FlashcardDeck).where(FlashcardDeck.user_id == student.id).limit(1)
            )
        ).scalar_one_or_none()
        if not deck:
            deck = FlashcardDeck(
                user_id=student.id,
                title="Formules clés Bac C & GCE A-Level",
                description="Identités trigonométriques, lois de Newton et thermodynamique.",
                subject="Mathematics",
            )
            session.add(deck)
            await session.flush()
            session.add_all(
                [
                    Flashcard(
                        deck_id=deck.id,
                        front="Formule d'Euler pour cos(θ) ?",
                        back="cos(θ) = (e^(iθ) + e^(-iθ)) / 2",
                    ),
                    Flashcard(
                        deck_id=deck.id,
                        front="Deuxième loi de Newton (système à masse constante) ?",
                        back="ΣF_ext = m · a (la somme des forces extérieures égale masse × accélération).",
                    ),
                ]
            )

        # 6. Study Group
        group = (
            await session.execute(
                select(StudyGroup)
                .where(StudyGroup.name == "Team Bac C & GCE AL Yaoundé")
                .limit(1)
            )
        ).scalar_one_or_none()
        if not group:
            group = StudyGroup(
                name="Team Bac C & GCE AL Yaoundé",
                description="Entraide quotidienne sur les annales de Maths et Physique.",
                exam_system="BAC",
                exam_level="Terminale",
                subject="Mathematics",
                creator_id=student.id,
                is_private=False,
                member_count=1,
            )
            session.add(group)
            await session.flush()
            session.add(StudyGroupMember(group_id=group.id, user_id=student.id))

        # 7. CMS Content strings
        for key, grp, val_fr, val_en, desc in CMS_DEFAULTS:
            existing_cms = (
                await session.execute(
                    select(ContentString).where(ContentString.key == key)
                )
            ).scalar_one_or_none()
            if not existing_cms:
                session.add(
                    ContentString(
                        key=key,
                        group=grp,
                        value_fr=val_fr,
                        value_en=val_en,
                        description=desc,
                        updated_by=admin.id,
                    )
                )

        # 8. AI Config default
        ai_cfg = (
            await session.execute(
                select(AIConfig).where(AIConfig.is_active.is_(True)).limit(1)
            )
        ).scalar_one_or_none()
        if not ai_cfg:
            ai_cfg = AIConfig(
                name="default",
                system_prompt=(
                    "Tu es MINDORA, tuteur académique d'élite pour le Cameroun et l'Afrique. "
                    "Réponds dans la langue de l'élève (FR ou EN), structure clairement étape par étape, "
                    "cite les annales ou documents du cours quand ils sont disponibles, et reste rigoureux."
                ),
                model="gemini-3.1-flash-lite",
                temperature=0.4,
                max_tokens=1400,
                language="fr",
                is_active=True,
                updated_by=admin.id,
            )
            session.add(ai_cfg)
            await session.flush()
            session.add(
                AIConfigVersion(
                    config_id=ai_cfg.id,
                    version=1,
                    system_prompt=ai_cfg.system_prompt,
                    model=ai_cfg.model,
                    temperature=ai_cfg.temperature,
                    max_tokens=ai_cfg.max_tokens,
                    notes="Initial bootstrap v1",
                    published_by=admin.id,
                )
            )

        await session.commit()
        print("MINDORA demo seed completed cleanly.")


if __name__ == "__main__":
    asyncio.run(seed_demo())
