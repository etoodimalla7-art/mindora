# MINDORA — Technical Architecture

## 1. System Overview

MINDORA is a cross-platform AI education platform composed of three independently
replaceable layers:

```
┌─────────────────────────────┐
│   Flutter Client (mobile/   │
│   desktop) — presentation   │
└──────────────┬───────────────┘
               │ REST/JSON (+ WebSocket for chat/voice)
┌──────────────▼───────────────┐
│   FastAPI Backend             │
│   - Auth, Users, Profiles     │
│   - Documents & Contribution  │
│   - Planner / Study Sessions  │
│   - Quiz / Flashcard / Exam   │
│   - Credits / Subscriptions   │
│   - Notifications             │
└──────────────┬───────────────┘
               │
┌──────────────▼───────────────┐
│   AI Orchestration Layer      │
│   (see AI_ARCHITECTURE.md)    │
│   - Intent router              │
│   - Tool executors (RAG, web,  │
│     math, OCR, STT/TTS, vision)│
└──────────────┬───────────────┘
               │
┌──────────────▼───────────────┐
│  PostgreSQL │ Object Storage  │
│  │ Vector DB (pgvector)       │
└───────────────────────────────┘
```

Every provider (LLM, storage, payment, search) sits behind an interface in
`backend/api/integrations/` so it can be swapped without touching business logic.

## 2. Backend (Python / FastAPI)

```
backend/
  api/
    core/            # config, security, logging, exceptions, deps
    integrations/     # provider adapters (llm, storage, payment, search, ocr, tts/stt)
    modules/
      auth/
      users/
      documents/
      past_papers/
      planner/
      study_sessions/
      ai_chat/
      flashcards/
      quizzes/
      mock_exams/
      progress/
      notifications/
      credits/
      subscriptions/
      admin/
    main.py
  alembic/            # DB migrations
  tests/
```

Each module follows: `router.py`, `schemas.py`, `service.py`, `repository.py`,
`models.py`. Routers only orchestrate; business rules live in `service.py`;
DB access lives in `repository.py`.

## 3. Frontend (Flutter / Dart)

```
frontend/mindora_app/lib/
  core/
    theme/           # design tokens: color, type, spacing, radius, elevation
    routing/
    network/         # api client, interceptors
    storage/          # secure storage, local cache
    error/
    l10n/             # en.arb, fr.arb
  domain/             # entities + use cases (pure Dart, no Flutter deps)
  data/               # repositories implementing domain contracts, DTOs
  presentation/
    features/
      onboarding/
      auth/
      home/
      ai_assistant/
      planner/
      documents/
      past_papers/
      flashcards/
      quizzes/
      mock_exams/
      progress/
      profile/
      admin/
    shared_widgets/
  main.dart
```

State management: Riverpod (stable, testable, no BuildContext coupling —
selected for the "professional state-management solution" requirement).
Branding lives entirely in `core/theme/brand_config.dart` so name/logo/colors
can change without touching architecture.

## 4. Data Layer

- PostgreSQL: relational entities (see DATABASE_SCHEMA.md)
- pgvector extension (or standalone vector DB) for embeddings powering
  course-aware retrieval
- Object storage (S3-compatible) for uploaded documents/media, abstracted
  behind `StorageProvider` interface

## 5. Cross-Cutting Concerns

- **Config**: `.env` via pydantic-settings; `.env.example` checked in
- **Security**: JWT access/refresh tokens, bcrypt/argon2 password hashing,
  rate limiting (slowapi), input validation everywhere, no secrets in Flutter
- **i18n**: all UI strings in `.arb` files (en, fr); backend returns
  locale-neutral codes, client renders localized copy
- **Error handling**: backend raises typed `AppError`s mapped to safe,
  user-facing messages; Flutter never surfaces raw exceptions
- **Observability**: structured logging + request IDs; audit log table for
  moderation/security-sensitive actions

## 6. Replaceability Matrix

| Concern         | Interface                     | Default implementation |
|-----------------|--------------------------------|--------------------------|
| LLM provider     | `LLMProvider`                  | Anthropic API adapter    |
| Vector search    | `VectorStore`                  | pgvector adapter         |
| Object storage   | `StorageProvider`               | S3-compatible adapter    |
| Web search       | `WebSearchProvider`             | pluggable search API     |
| Payment          | `PaymentProvider`               | placeholder (mobile money/card, configured later) |
| STT/TTS          | `SpeechProvider`                | pluggable adapter        |
