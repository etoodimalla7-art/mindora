# MINDORA Architecture & Engineering Decisions

This log captures engineering decisions added during final integration & hardening (`DEC-069` onwards). Earlier design decisions (`DEC-001`–`DEC-068`) are embedded across the baseline architecture in `ARCHITECTURE.md`, `API_MAP.md`, `DATABASE_SCHEMA.md`, and `AI_ARCHITECTURE.md`.

## DEC-069 — Admin Panel Framework Choice (React + Vite + TypeScript)
- **Date**: 2026-11-18
- **Status**: Accepted
- **Context**: The host container does not ship the Flutter SDK (only Node.js 22, JDK 21, Android SDK 36, and Python 3.12). While `frontend/flutter_app/lib/features/admin` remains available in git history (`2601ff0`) as reference, building/verifying production admin assets requires a native toolchain in CI and locally.
- **Decision**: Implement the standalone Admin Portal (`mindora/admin/`) in React 19 + Vite + TypeScript + Tailwind CSS + Vitest, mirroring all 12 Flutter Admin modules with mandatory 2FA, RBAC UI gating, live WebSocket `/admin/events`, FR/EN i18n, and design tokens.
- **Consequences**: Full Vitest test suite, production bundle verification, and direct Vercel deployment (`admin.mindora.dev`) work out-of-the-box alongside unified preview hosting at `/admin`.

## DEC-070 — Mandatory Admin 2FA via Challenge Token + OTP
- **Date**: 2026-11-18
- **Status**: Accepted
- **Context**: Administrative accounts have privileged access over users, documents, AI system prompts, and maintenance flags.
- **Decision**: Add dedicated `/api/v1/auth/admin/login`, `/api/v1/auth/admin/2fa/verify`, and `/api/v1/auth/admin/2fa/resend` endpoints using the existing `otp_codes` table (`purpose="login_2fa"`) and short-lived `admin_2fa_challenge` JWT tokens.
- **Security**: Neither OTP codes nor JWTs or secrets are ever logged (`smtp.py` fallback log-mode redacts message bodies).

## DEC-071 — Server-Side Mock Exam Grading Guarantee
- **Date**: 2026-11-18
- **Status**: Accepted (Enforced)
- **Context**: Client applications must never receive correct answers or explanations while a mock exam is `pending` or `in_progress`.
- **Decision**: `MockExamService` strictly strips `correct_index` and `explanation` until `exam.status == "graded"` (`POST /mock-exams/{id}/submit`). Android mobile client parses nullable `correctIndex`/`explanation` and displays them only post-submission.

## DEC-072 — Public Aggregated Settings & Support Contact Endpoints
- **Date**: 2026-11-18
- **Status**: Accepted
- **Context**: Both the Android mobile app, Admin portal, and Public marketing site need live feature flags, maintenance status, supported exam systems/subjects/levels, and localized CMS copy without requiring auth at boot.
- **Decision**: Expose `GET /api/v1/settings/public` (plus `/settings/maintenance`) and `POST /api/v1/support/contact` + student `/support/tickets/*` endpoints backed by PostgreSQL (`app_settings`, `feature_flags`, `content_strings`, `support_tickets`).

## DEC-073 — Multimodal AI Vision & Voice Tutor Contracts
- **Date**: 2026-11-18
- **Status**: Accepted
- **Context**: Mobile students need photo-to-solution homework help (`/ai/vision`) and conversational speech tutor (`/ai/voice`).
- **Decision**: Add `POST /api/v1/ai/vision` (base64 JPEG/PNG/WebP/GIF up to 5MB → `GeminiChatProvider`) and `POST /api/v1/ai/voice` (Android `SpeechRecognizer` transcript → concise tutor reply + `TextToSpeech` sanitized text/locale). Returns HTTP `503 ai_unconfigured` cleanly if `GEMINI_API_KEY` is absent.

## DEC-074 — Unified Gateway Preview & Android SQLite Offline-First Sync
- **Date**: 2026-11-18
- **Status**: Accepted
- **Context**: The mobile Android app previously relied on `SharedPreferences` (`MindoraStore`) with local dummy data.
- **Decision**: Replace local-only persistence with Retrofit + OkHttp + JWT Refresh `TokenAuthenticator` + `EncryptedSharedPreferences` + SQLite (`SQLiteOpenHelper` `OfflineCacheDb`) JSON snapshot cache and offline pending action queue (`complete_session`, `review_card`), pointing default `BuildConfig.API_BASE_URL` to the live FastAPI backend.

## DEC-075 — Live Android Client Full Feature Parity & Native Tooling
- **Date**: 2026-11-19
- **Status**: Accepted
- **Context**: All student features must operate live against FastAPI while remaining lightweight, SDK-24 compatible, and testable on pure JVM without external native DB dependencies.
- **Decision**:
  - Implement SSE token streaming (`SseChatClient`), camera/gallery exercise Vision compression + Base64 upload, Android `SpeechRecognizer` + `TextToSpeech` bilingual voice loop, native `PdfRenderer` modal viewer for downloaded past papers, Flutterwave checkout via embedded `WebView`, live `OkHttp` WebSocket study groups with online presence, and bilingual FR/EN UI (`values/strings.xml`, `values-fr/strings.xml`).
  - Extract `TokenStorage` interface for `SecureTokenStore` to enable pure-JVM `MockWebServer` unit testing (`Sm2AndSecurityTest`, `NetworkApiTest`).
  - Configure ProGuard/R8 shrinking (`isMinifyEnabled = true`, `isShrinkResources = true`) for release builds.

## DEC-076 — F-13 Notification Rules, Daily Cap & Quiet Hours
- **Date**: 2026-11-19
- **Status**: Accepted
- **Context**: Push and in-app notifications must prevent student fatigue while staying testable across timezones.
- **Decision**: Introduce `notification_rules` (`0026_notification_rules`) with per-trigger cooldowns, enforce timezone-aware quiet hours (`22h–07h` via `ZoneInfo` + injectable `now_fn`), cap deliveries via `max_per_day` in `NotificationEngine`, and expose `"BLOQUÉ PAR : clé Firebase"` in `/notifications/preferences` and `/notifications/status` when Firebase credentials are absent.

## DEC-077 — Public/Admin Settings Split & Audited Feature Flags
- **Date**: 2026-11-19
- **Status**: Accepted
- **Context**: Public clients need configuration and feature rollouts without leaking internal admin settings or permitting un-audited flag flips.
- **Decision**: Add `category` and `is_public` to `app_settings` and `rollout_percentage` + `environment` to `feature_flags` (`0027_settings_flags_b3`), restrict `/settings/public` strictly to `is_public=True`, and log all admin settings/flag mutations via `AuditService.log`.

## DEC-078 — RGPD Analytics Event Allowlist & Retention Windows
- **Date**: 2026-11-19
- **Status**: Accepted (Enforced)
- **Context**: Product analytics (`0029_analytics_events`) must measure engagement and J1/J7/J30 cohort retention without storing conversation transcripts, prompts, or PII.
- **Decision**: Enforce strict `ALLOWED_ANALYTICS_EVENT_TYPES` and reject metadata keys containing PII/prompt/message text at Pydantic validation (`app/schemas/analytics.py`), while exposing `J1`/`J7`/`J30` retention buckets in `/api/v1/admin/analytics/retention`.

## DEC-079 — Server-Side Student Progress, Streaks & Revision Recommendations
- **Date**: 2026-11-19
- **Status**: Accepted
- **Context**: Client-computed streaks and mastery statistics can be manipulated or drift across offline devices.
- **Decision**: Persist consolidated student metrics in `user_progress` (`0030_user_progress`), recompute streaks (`streak_current`, `streak_best`) and 30/90-day activity heatmaps server-side from completed `study_sessions` and SM-2 cards, and generate prioritized recommendations (`due_flashcards` → `weakest_topic` → `default_practice`).

## DEC-080 — Soft-Deleted Bilingual Curriculum Content CRUD
- **Date**: 2026-11-19
- **Status**: Accepted
- **Context**: Curriculum subjects, chapters, and announcements managed from the Admin Portal must remain referentially safe for historical student progress and mock exams.
- **Decision**: Add `subjects`, `chapters`, and `announcements` (`0031_admin_curriculum_content`) with `deleted_at` soft-delete timestamps, mandatory FR+EN localized titles/bodies, and `AuditLog` entries on every create/update/delete operation.

## DEC-081 — Justified Single-Student Exam Inspection (`ExamReadRequest`)
- **Date**: 2026-11-19
- **Status**: Accepted (Enforced)
- **Context**: Support admins occasionally need to inspect a student's graded mock exam copy to resolve disputes, without enabling bulk surveillance of student scores.
- **Decision**: Gate `GET /api/v1/admin/students/{student_id}/exams` behind a prior written justification (`POST .../read-request`, minimum 10 non-blank characters stored in `exam_read_requests` via `0032_exam_read_requests`), scoped strictly to one `(admin_id, student_id)` pair, and write `AuditLog` entries on both request and read.

## DEC-082 — Versioned AI Config JSONB Snapshots & Rollback
- **Date**: 2026-11-19
- **Status**: Accepted
- **Context**: Updating live tutor system prompts or model hyperparameters requires atomic versioning, deterministic rollback, and clear external-key observability.
- **Decision**: Track `active_version` on `ai_configs` and store full JSONB configuration snapshots (`system_prompt`, `model`, `temperature`, `max_tokens`, `language`) per version in `ai_config_versions` (`0033_ai_config_snapshot`), write `AuditLog` records for `update`/`publish`/`rollback`, and surface `"BLOQUÉ PAR : clé Gemini"` when `GEMINI_API_KEY` is unconfigured.

