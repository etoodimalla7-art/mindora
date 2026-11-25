# MINDORA — Development Roadmap

Status legend: ✅ scaffolded this session · ⏳ next · ⬜ later

| Phase | Scope | Status |
|-------|-------|--------|
| 1 | Architecture + project setup + design system + app shell | ✅ |
| 2 | Auth + onboarding flow | ✅ |
| 3 | Home dashboard | ✅ |
| 4 | Course/document data model + upload UI | ✅ |
| 5 | Document validation & analysis pipeline | ✅ |
| 6 | Past papers library | ✅ |
| 7 | Study planner | ✅ |
| 8 | AI orchestration layer (backend) | ✅ |
| 9 | AI tutor | ✅ |
| 10 | Flashcards + quizzes | ✅ |
| 11 | Mock exams | ✅ |
| 12 | Progress analytics | ✅ |
| 13 | Voice + vision | ✅ |
| 14 | Notifications | ✅ |
| 15 | Credits + subscription | ✅ |
| 16 | Admin/moderation | ✅ |
| 17 | Security hardening | ✅ |
| 18 | Testing | ✅ |
| 19 | Android release | ✅ (this delivery) |
| 20 | Windows release | ✅ (this delivery) |

**All 20 phases of the original roadmap are now complete.** What
remains from here is real compilation, real device testing, real
branding/legal decisions, and real deployment — none of which a
sandboxed code environment can do. See "What to actually do next"
in the guidance the assistant gave alongside this delivery.

## What's in this delivery (Phase 1)

**Docs**: ARCHITECTURE.md, AI_ARCHITECTURE.md, DATABASE_SCHEMA.md, API_MAP.md,
this roadmap.

**Backend**: FastAPI skeleton — app factory, config via `.env`, health route,
module folder structure, SQLAlchemy base models for `users` and
`education_profiles`, `.env.example`.

**Frontend**: Flutter skeleton — `pubspec.yaml` with Riverpod + go_router,
`core/theme` design tokens (color/typography/spacing/radius/elevation),
light+dark theme, `brand_config.dart` for swappable branding, app shell with
bottom navigation (Home/AI/Planner/Learn/Profile) and placeholder screens
that already carry the visual language (not blank/unfinished-looking).

## What's in this delivery (Phase 2)

**Backend**: full `auth` module — register/login/refresh/logout,
forgot/reset password (dev-stub email provider behind a swappable
`EmailProvider` interface, no email enumeration), and `users` module
education-profile GET/PUT used by onboarding.

**Frontend**: `core/network/api_client.dart` (Dio, auth header injection,
automatic access-token refresh on 401), `core/storage/token_storage.dart`
(secure storage for tokens only), `AuthController` (single source of
truth for auth state), full auth screens (splash, welcome, login,
register, forgot password), and the complete 11-step onboarding flow
(intro → language → country → education system → level → academic
profile → study goals → learning preferences → notifications → AI
personalization → completion) which submits the collected profile to
`PUT /users/me/education-profile`. `app_router.dart` now redirects
centrally based on auth + onboarding state — no screen manually
navigates on session expiry.

## What's in this delivery (Phase 3)

**Backend**: `study_sessions` module (`GET /today`, start/complete/skip)
and `progress` module (`GET /overview` with streak calculation from
completed sessions, `GET /readiness/{exam}` returning a safe "not enough
data yet" error until a score exists). `StudyPlan`/`StudySession` models
use denormalized subject/topic name strings for now rather than FKs into
a course catalog — the catalog is built in Phase 4; this keeps the
dashboard shippable without blocking on it.

**Frontend**: dashboard domain entities + repository + Riverpod
providers (`todaySessionsProvider`, `dashboardOverviewProvider`,
`completeSessionActionProvider` which invalidates both on completion).
`HomeScreen` rewritten to consume real data with loading/error/empty
states — a brand-new account still correctly shows the "set your exam
goal" empty state rather than fake numbers (section 13's explicit
requirement). New widgets: `StreakChip`, `TodaySessionCard`,
`WeakSubjectBanner`.

**Known placeholder**: "Start Session" currently marks the session
complete directly (no timer/focused study UI yet) so the
streak/progress loop is demoable end-to-end; the real focused
study-session interface (section 49) is a Phase 9+ item.

## Next session (Phase 4 suggestion)
Course/document data model + upload UI: Subject/Course/Topic catalog
tables (finally giving study_sessions real FKs), the document upload
flow with the 500-word description requirement, and metadata forms
(sections 17-20).

## What's in this delivery (Phase 4)

**Backend**: `catalog` module (Subject/Course/Topic tables + `GET
/catalog/subjects`), `documents` module (Document, DocumentMetadataExam,
DocumentValidation, DocumentAnalysis models; upload/metadata/exam-metadata/
submit/status/mine endpoints), a `StorageProvider` interface (dev-only
local-disk stub, swappable for S3/GCS later — same pattern as
`EmailProvider`), and `documents/validation.py` — the real 500-word
minimum plus a repeated-word spam heuristic (section 18), unit-tested
inline. `submit` records a `DocumentValidation` row and routes the
document to `NeedsRevision` (with specific problems returned to the
client) or `UnderReview` — full OCR/duplicate-detection is Phase 5.

**Frontend**: 3-screen upload flow (pick file → metadata with a *live*
word counter mirroring the backend's 500-word rule → optional exam
metadata → submit), a `DocumentStatusChip` mapping the 9-state lifecycle
to readable labels/colors, and `LearnScreen` now lists the contributor's
real documents instead of a permanent placeholder.

**Deferred**: `study_sessions` still uses denormalized subject/topic
strings rather than FKs into the new catalog tables — wiring that up
is bundled into Phase 7 (study planner), which is what will actually
create sessions from real Course/Topic rows.

## Next session (Phase 5 suggestion)
Document validation & analysis pipeline: OCR/text extraction, language
detection with mismatch flagging (section 20), subject/level
auto-detection, and duplicate detection (sections 21, 25) — the parts
of the `UNDER REVIEW` → `Approved` transition that are still manual
today.

## What's in this delivery (Phase 5)

**Backend**: real text extraction (`pypdf` for PDFs, `python-docx` for
Word, `pytesseract`+Pillow for images — OCR degrades to empty text
rather than failing if Tesseract isn't installed on the host, since
image OCR is a quality signal, not a hard gate). Language detection via
`langdetect` with declared-vs-detected mismatch flagging (section 20) —
**tested against real English/French text in this session, correctly
detects and flags mismatches**. Subject/level classification is a
keyword-frequency heuristic (v1, documented as swappable for an
embedding-based classifier later). Duplicate detection: exact
content-hash match + fuzzy text-similarity against other documents,
flagging (never auto-rejecting, per section 25) matches ≥85% similar.

`submit` now runs the full pipeline, persists a `DocumentAnalysis` row,
records a `DocumentValidation` row per check, and returns both blocking
`problems` (bad description, language mismatch) and non-blocking
`warnings` (category mismatch, possible duplicate) for moderator
attention.

**Verified this session**: language detection/mismatch logic, PDF
extraction (including the corrupted-file failure path returning a safe
message per section 22), duplicate hash matching, and the full pipeline
running end-to-end — all confirmed working with real installed
libraries, not just syntax-checked.

**Frontend**: submit screen now shows moderator-facing warnings
alongside blocking problems.

## Next session (Phase 6 suggestion)
Past papers library: `past_papers`/`examinations` tables, the
browse-by-country/system/exam/level/subject/year hierarchy (section 30),
and search/filter/bookmark UI.

## ⚠️ Cross-cutting fix in this session (affects Phases 2-5, not just Phase 6)

While integration-testing Phase 6, discovered that **every repository
written in Phases 2-5 had the same bug**: SQLAlchemy's `Uuid` column
type requires actual `uuid.UUID` instances at query time, but routers
pass `str(current_user.id)` and URL path params (also strings) straight
through. This raised `AttributeError: 'str' object has no attribute
'hex'` on essentially every authenticated request and every lookup by
ID — including the `get_current_user` dependency itself, meaning **no
authenticated endpoint would have actually worked** despite passing
syntax checks and (unrun) code review in every prior phase's delivery.

Fixed by adding `api/core/ids.py::to_uuid()` and applying it at every
repository query site and in `core/deps.py`, across `auth`, `users`,
`study_sessions`, `progress`, `documents`, and `catalog` — not just the
new `past_papers` module. **This session is the first time any backend
module was tested against a real database rather than only
`py_compile`'d** — an in-memory SQLite integration test (create tables,
seed data, run real queries) now confirms auth, education-profile,
study-session, progress, document, and past-paper repositories all work
correctly with string IDs exactly as routers pass them, including a
full JWT create → decode → DB-lookup round trip.

**Lesson for future phases**: `py_compile` only catches syntax errors;
it does not catch type/runtime errors like this one. From here on,
each phase should include at least one in-memory-SQLite integration
test per new repository, not just a syntax check, before being called
done.

## What's in this delivery (Phase 6)

**Backend**: `past_papers` module — `Examination`/`PastPaper`/
`PastPaperBookmark` models, `GET /past-papers` (filterable by country/
system/level/subject/year/free-text search), `GET /past-papers/filters`
(distinct values for cascading dropdowns), and bookmark add/remove/list.
A dev-only seed script (`scripts/seed_past_papers.py`) since past papers
normally arrive via the admin approval pipeline (Phase 16), which
doesn't exist yet.

**Verified this session**: full integration test — real tables created
in SQLite, seeded with 2 examinations/2 subjects/3 papers, then search
(unfiltered, subject-filtered, year-filtered), filter aggregation, and
a complete bookmark add → verify → remove → verify round trip, all
against real queries with string IDs.

**Frontend**: `PastPapersScreen` with cascading filter dropdowns
(country → system → level → subject → year), free-text search, and
bookmark toggling wired to real invalidate-on-mutation providers.
Reached from Learn's toolbar and its empty state (section 71: kept out
of the bottom nav).

## Next session (Phase 7 suggestion)
Study planner: exam-mode and subject-mode plan creation (sections
31-34), and — per the Phase 4 deferral note — wiring `study_sessions`
to real Course/Topic rows from the catalog instead of denormalized
strings, since the planner is what actually generates sessions.

## What's in this delivery (Phase 7)

**Backend**: `planner` module — `build_session_plan()` (pure function:
round-robins subjects day-by-day, cycles each subject's topics, falls
back to a "General review" placeholder for subjects with no catalog
topics yet — unit-tested standalone before anything was built on it),
exam-plan and subject-plan creation, plan/session retrieval, and a
`reschedule` endpoint (section 34's "recalculate when behind," in its
simple form: pushes missed/pending sessions to start today, preserving
order — smarter weak-topic prioritization needs quiz data that doesn't
exist until Phase 11-13, noted rather than faked).

`study_sessions.subject_id`/`topic_id` are now real FKs into the
catalog (the Phase 4 deferral is resolved) — populated when a matching
subject/topic exists, `None` when it doesn't, with the denormalized
name/title strings kept as a display cache either way.

**Verified this session** (continuing the integration-test discipline
from the Phase 6 bug): a full in-memory-SQLite test seeding one subject
with real catalog topics and one without, then asserting — exam-plan
FK wiring is correct for the subject with topics, the fallback path
triggers correctly for the one without, subject-plan's explicit-topic
mode works, cross-user ownership is blocked, a past exam date is
rejected, and reschedule correctly resequences missed/pending sessions
starting today. All assertions passed on first run.

**Frontend**: mode-choice screen, exam-plan and subject-plan creation
forms, and a plan summary screen listing every generated session.
Wired from both the Planner tab's empty state and the Home dashboard's
"Set my exam goal" action (previously a dead button since Phase 3).

**Deferred**: university mode (section 33 — generating a plan from an
uploaded course outline/syllabus) needs document-content parsing
beyond what the Phase 5 pipeline extracts; noted for a later phase
rather than stubbed with fake behavior.

## Next session (Phase 8 suggestion)
AI orchestration layer (backend): the intent-router / context-builder /
tool-selector / executor pipeline from AI_ARCHITECTURE.md, starting
with plain text chat (course-aware retrieval + general LLM fallback)
before voice/vision/math-solver tools are added in later phases.

## What's in this delivery (Phase 8)

**Backend**: the AI_ARCHITECTURE.md pipeline, text-chat scope —
`classify_intent()` (heuristic: greeting vs. question, kept simple and
debuggable per section 15's "must not use every tool for every
question"), `retrieve_course_context()` (keyword-overlap retrieval over
a student's own Phase-5-extracted document text — v1, documented as
swappable for embeddings once pgvector is wired up), and an
`LLMProvider` interface with a `MockLLMProvider` (deterministic,
no-network dev stand-in) and an `AnthropicLLMProvider` production
adapter shape — same Replaceability Matrix pattern as every other
provider in this codebase. `ChatOrchestrator` ties them together:
greetings skip retrieval entirely; questions try the student's own
course material first and say so explicitly, falling back to labeled
general knowledge only when nothing relevant exists (section 16/76 —
never blur the two, never fabricate a source).

New `ai_chat` module: `Conversation`/`Message` tables (with a
`tool_trace` JSON column recording intent/tools_used/source per
assistant reply, so "what did the AI actually do" is always
inspectable), `POST /ai/chat`, and conversation history endpoints.

**Verified this session, in layers** (pure functions first, then the
orchestrator, then the full DB-backed flow):
- Unit-tested `classify_intent` and `retrieve_course_context` in
  isolation — **and this caught a real bug**: naive word-overlap scoring
  let common stopwords ("the", "of", "is") produce false-positive course
  matches, so "what is the capital of France?" would have been
  confidently answered as if it came from a calculus document. Fixed
  with a stopword filter before scoring, then re-verified against the
  exact query that exposed it.
- Unit-tested the LLM provider factory and the Anthropic adapter's pure
  request-body builder (no live API key needed or used).
- Tested `ChatOrchestrator` standalone with a recording fake LLM: greeting
  skips retrieval, a real course match is used and labeled, an unrelated
  question correctly falls back to general knowledge, and an empty
  document corpus never crashes.
- Full in-memory-SQLite integration test exercising the real service:
  conversation creation and title, message persistence with correct
  `tool_trace`, multi-turn conversations, empty-message rejection,
  cross-user access blocked, and conversation listing — all against a
  real database, real orchestrator, and a mock LLM (no external calls).

**Frontend**: `AiAssistantScreen` rewritten from a static placeholder
to a real chat UI — message bubbles, a "From your course material" tag
when the backend used the course retriever, loading state, and error
handling. Camera/voice buttons remain placeholders (Phase 13).

## Next session (Phase 9 suggestion)
AI tutor behaviors: Socratic mode (section 37), adapting explanation
depth/style on request ("explain it more simply", "give me an
exercise"), and the focused study-session interface (section 49) that
Phase 3's dashboard flagged as a placeholder.

## What's in this delivery (Phase 9)

**Backend**: `tutor_style.py` — pure keyword detection for style
requests (simpler/detailed/university-level explanations, worked
examples, step-by-step breakdowns, practice exercises, Socratic mode
on/off), unit-tested standalone before anything used it. Preferences
merge into (never replace) `Conversation.style_preferences` — a new
JSON column, section 59's per-conversation preference memory — so
"explain it more simply" said once keeps applying to every later
message in that conversation without the student repeating themselves.
`ChatRequest` gained an optional `socratic_override` field so a UI
toggle can flip Socratic mode instantly regardless of message text.

**Verified this session, in the now-familiar three layers**: pure
`tutor_style` functions tested alone; `ChatOrchestrator` tested
standalone with a fake LLM proving style persists across simulated
turns and an explicit override merges correctly with existing
preferences; then a full in-memory-SQLite test proving the preference
*actually reloads from a real database row* on a second, separate
`send_message` call — not just held in Python state — which is the
one thing a shallower test could have missed and called done anyway.

**Frontend**:
- `AiAssistantScreen` gained a Socratic-mode toggle (lightbulb icon)
  that sends an explicit override with the next message only, then
  lets the backend's persisted preference carry it forward.
- **The focused study-session interface (section 49)**, a real screen
  at last: subject/topic, a countdown timer with pause/resume, and an
  "Ask AI Tutor about this topic" button that hands off to the chat tab
  with a pre-filled, topic-specific opening message
  (`pendingTutorPromptProvider`, auto-sent on arrival). Pushed as a
  full-screen route outside the bottom-nav shell, per the spec's
  "minimize distractions." Home's "Start Session" button — a
  Phase-3-flagged placeholder that just marked sessions complete
  directly — now opens this real screen instead.

## Next session (Phase 10 suggestion)
Flashcards + quizzes (sections 38-40): generation from a document's
extracted text or a topic, spaced-repetition review state for
flashcards, and a multiple-choice/true-false/short-answer quiz engine
with difficulty levels.

## What's in this delivery (Phase 10)

**Backend**: `flashcards/generation.py` and `quizzes/generation.py` —
extractive, dependency-free generators over a document's Phase-5-
extracted text (finds "X is Y" sentences, turns them into flashcards or
multiple-choice questions with plausible distractors drawn from other
definitions in the same text). Same documented-as-swappable-for-LLM
philosophy as classification.py (Phase 5) and generation.py (Phase 7) —
works with no API key, fully unit-testable. `spaced_repetition.py`
schedules review intervals (known grows 1→2→4→7→14→30 days, uncertain
resets to 1 day, forgotten comes back in 4 hours) — a deliberately
simple, predictable algorithm rather than full SM-2.

New `flashcards` and `quizzes` modules: generate/list/review endpoints
for flashcards, generate/attempt/results endpoints for quizzes (correct
answers withheld until submission, then returned as "detailed
corrections" per section 40).

**Two real bugs caught by testing in this phase**, on top of the design
verification:
1. The definition extractor initially treated pronoun-led sentences
   ("This is not a great example...") as if the pronoun were the term
   being defined — caught because I test with adversarial input, not
   just happy-path text, and fixed with a pronoun/stopword filter on
   the extracted term.
2. The quiz generator's first draft always placed the correct answer in
   the same relative position after a naive sort — which would have
   made every generated quiz gameable without knowing any content.
   Caught by explicitly asserting the correct-answer position *varies*
   across questions, not just that it's present; fixed with a
   per-question deterministic shuffle.
3. (Carried from the flashcard scheduling integration test) SQLite
   doesn't preserve timezone-awareness on `DateTime(timezone=True)`
   columns on read-back, causing a naive/aware comparison crash in
   `list_due`. Fixed defensively — this is exactly the kind of gap a
   syntax check would never surface, only a real database round-trip.

**Verified end-to-end**: a full in-memory-SQLite test generating real
flashcards and a real quiz from actual extracted document text, then
exercising the full spaced-repetition lifecycle (known/uncertain/
forgotten all producing correctly different due-list behavior, streaks
correctly continuing across separate review calls), quiz scoring
(100% and 50% cases with correct per-question breakdowns), stored
result retrieval, and cross-user access blocked on both flashcards and
quizzes.

**Frontend**: a flip-card flashcard review screen (tap to reveal, then
rate known/uncertain/forgotten) and a quiz-taking flow (question
navigation → submit → detailed per-question results screen showing
right/wrong with correct answers). Both reachable from a document's
"Review flashcards / Take a quiz" menu in Learn, and from the focused
study-session screen for the session's topic.

## Next session (Phase 11 suggestion)
Mock exams (section 40): timed, multi-subject exams assembled from the
quiz engine with a countdown, question navigation, and a results
breakdown — the natural extension of this phase's quiz infrastructure.

## What's in this delivery (Phase 11)

**Backend**: `mock_exams` module built directly on Phase 10's quiz
engine rather than duplicating question storage — each subject in a
mock exam is a real `Quiz`+`Question` set (same generation, same
scoring philosophy), linked via a new `MockExamSection` table. A mock
exam pulls from *all* of a student's documents tagged with a subject
(not just one, unlike a standalone quiz), so exam sections draw on
broader material. `scoring.py` — pure aggregation of per-section
correct/total counts into an overall score plus a subject-by-subject
breakdown, unit-tested first including the zero-questions-in-a-subject
edge case before any service code used it.

One bug caught while wiring the service together, before it ever ran:
`get_latest_results` referenced `attempt.answers` to rebuild
corrections, but the `MockExamAttempt` model only stored
`section_scores` — the raw answers were never persisted. Caught by
re-reading the service against the model it was written to use, not by
a failing test; added the missing `answers` JSON column and fixed the
reference before the first integration-test run, which is cheaper than
catching it after.

**Verified end-to-end**: a full in-memory-SQLite test with two real
uploaded documents (Biology, Mathematics), a real 2-subject mock exam
generated from them, a submission scoring 100% on one subject and 0%
on the other (correctly combining to 50% overall — not averaged
naively, weighted by actual question counts), stored results correctly
retrievable later, cross-user access blocked, and a subject with zero
matching documents still producing a usable fallback section instead
of breaking exam creation.

**Frontend**: a setup screen (subject multi-select, questions-per-
subject, duration, difficulty), a timed taking screen with a countdown
that auto-submits at zero and flat question navigation across all
sections (with a subject header, not a hard per-section barrier), and
a results screen showing the overall score, a per-subject breakdown,
then detailed question-by-question corrections. Reached from Learn's
toolbar.

## Next session (Phase 12 suggestion)
Progress analytics (section 41) and the exam readiness score (section
42): aggregating the study-session, quiz, and mock-exam data that now
actually exists into per-subject mastery charts and the multi-dimension
readiness score the Home dashboard has been showing a placeholder
banner for since Phase 3.

## What's in this delivery (Phase 12)

**Backend**: `progress/analytics.py` — pure aggregation functions
(quiz scores and flashcard known-ratios grouped by subject, blended
60/40 into a mastery score, weak-subject ratio, and the 6-dimension
readiness formula) — unit-tested first, including the case that
matters most for an honest product: **a brand-new student with zero
activity scores 0 across every dimension, never a reassuring-looking
default.** `ProgressService` was rewritten to compute both `/progress/
overview` and `/progress/readiness/{exam}` **live** from real
`QuizAttempt`, `FlashcardReview`, and `MockExamAttempt` rows on every
request, rather than reading the `progress`/`readiness_scores` tables —
those tables were defined back in Phase 1 but nothing had ever written
to them, so reading them would have silently returned nothing forever.
Persisted history for trend charts is deferred and noted as such,
rather than half-built.

**Verified end-to-end** with genuinely cross-module activity: seeded
real quiz attempts across two subjects, real flashcard reviews in one
of them, and a real mock-exam attempt, then hand-verified the exact
expected numbers — mastery blending (80 quiz / 66.7% flashcard →
74.7 blended), the overview's weakest-subject detection, the readiness
score's `knowledge` dimension averaging across ALL attempts, and that
adding a mock-exam score correctly raised the `past_papers` dimension
and the overall score. Also confirmed the brand-new-student path
returns overview data with no subjects (not an error) while readiness
correctly returns "not enough data yet" (an honest error, not a fake
number) — two different, deliberately different behaviors for the
same "no data" situation, both verified.

**One documented shortcut, not a silent gap**: section 42's "Past
Papers" readiness dimension is proxied by mock-exam performance, since
true past-paper-attempt tracking isn't built — the `past_papers`
module (Phase 6) only supports browsing and bookmarking, not taking a
paper and getting scored. Noted in code and here rather than quietly
treated as equivalent.

**Frontend**: `ReadinessScreen` — overall score, a prominent "this is
an estimate, not a guarantee" notice (section 42's explicit
requirement, not a buried disclaimer), and all 6 dimensions as labeled
progress bars. Reached from a new "View my exam readiness" button on
Home (prompts for the exam name via dialog for now — pre-filling from
the student's education profile is a follow-up once that data is
surfaced through a frontend provider, noted rather than faked).

## Next session (Phase 13 suggestion)
Voice + vision (sections 43-44): speech-to-text/text-to-speech for the
AI tutor chat, and a camera pipeline (capture → OCR/vision → question
understanding → the same orchestrator from Phase 8) for scanning
handwritten or textbook questions.

## What's in this delivery (Phase 13)

**Backend**: `SpeechProvider` interface (STT + TTS) with a
`MockSpeechProvider` dev stand-in — same Replaceability Matrix pattern
as every other provider in this codebase. `LLMProvider` gained an
optional `complete_with_image` method (default: `NotImplementedError`,
so providers without vision support fail predictably rather than
silently) with a real `AnthropicLLMProvider` implementation whose
multimodal request-body builder is a pure function, unit-tested
including a byte-for-byte base64 round-trip check.

`AiChatService` gained `send_voice_message` and `send_vision_message` —
both funnel into the *exact same, already-tested* `send_message`
pipeline from Phase 8/9 once the input is turned into text, rather than
duplicating orchestration logic for each modality. Vision mode tries
OCR first (Phase 5's extractor, reused) and only calls a vision-capable
LLM when OCR finds nothing usable — cheaper and works even with a
provider that can't see images.

**What's honestly untestable here, and why**: real speech transcription
accuracy and real image understanding can't be verified without a live
provider API key and, for STT, actual audio processing — this mirrors
Phase 8's Anthropic adapter, where only the request-building logic was
testable and the live call wasn't. What *is* fully tested: every
routing decision, every error path, and the entire pipeline once input
becomes text — which is most of the actual risk surface, since the
tutor logic itself (retrieval, style, persistence) is unchanged from
already-verified code.

**Verified end-to-end**, all four branches: a voice message
transcribing and flowing through the real orchestrator with persistence
confirmed; a vision message where a fake OCR extractor returns real
text (used directly, vision LLM never called); a vision message where
fake OCR returns nothing (correctly falls back to a vision-capable
mock LLM, confirmed called exactly once); and a vision message with
neither OCR text nor a vision-capable provider (a safe user-facing
error, not a crash). Plus empty-audio and empty-image rejection.

**Frontend**: real microphone recording (tap to start/stop, uploads on
stop) and real camera capture wired to the existing chat transcript —
the transcript/extracted question is shown as the user's message so a
student can see what was actually heard or read before trusting the
reply. Audio-reply playback plumbing is wired end-to-end (decode →
temp file → play) even though the dev mock provider never returns
audio yet, so it's ready the moment a real TTS provider is configured.

## Next session (Phase 14 suggestion)
Notifications (section 47): intelligent, non-spammy reminders (upcoming
sessions, missed-session recovery, exam countdown alerts) with
preferences, quiet hours, and the delivery mechanism (push
notifications via a service like FCM) to actually send them.

## What's in this delivery (Phase 14)

**Honest scope note first**: no scheduler or push-delivery
infrastructure (FCM/APNs) exists in this project, and adding one
reliably needs device-token registration and platform-specific setup
this environment can't verify. So this phase builds a real, working
**in-app notification center** — content generation, quiet hours,
preferences, dedup, all genuinely functional — and generates fresh
notifications whenever the list is fetched, rather than on a
background schedule. Push delivery is a clearly separate, deferred
addition (the `Notification` rows this phase creates are exactly what
a push provider would read from), not something quietly faked.

**Backend**: `notifications/generation.py` — pure functions for
quiet-hours checking and reminder content (session-upcoming,
session-missed, exam-countdown with the weakest subject named, reusing
Phase 12's mastery computation). Unit-tested first, including the case
most likely to hide a subtle bug: a midnight-wrapping quiet-hours
window (e.g. 22→7 meaning "10pm through 7am") along with the
non-wrapping and zero-width cases. `NotificationsService.generate_for_user`
scans upcoming/missed sessions and the active exam plan, dedupes
against already-created notifications by payload key, and respects
both the enabled flag and quiet hours.

**A real gap closed in the same phase**: onboarding's notification-
permission step (built in Phase 2) collected `notificationsEnabled`
and `preferredStudyTimes` from the student but never sent them
anywhere — there was nowhere to send them until this phase's
preferences table existed. Fixed: onboarding submission now also PUTs
`/notifications/preferences`.

**Verified end-to-end** against the actual current time (not a frozen
test clock) to make sure quiet-hours logic works against reality, not
just idealized inputs: full generation creating exactly the 3 expected
notification types from real study sessions and a real exam plan;
repeated generation calls producing zero duplicates; disabling
preferences suppressing generation entirely; and quiet hours
correctly suppressing generation when explicitly set to cover the
real current hour, then correctly resuming once quiet hours were
reopened.

**Frontend**: a notification center screen (unread highlighting,
tap-to-mark-read, pull-to-refresh) and a real unread-count badge on
Home's notification bell — which had been silently doing nothing since
Phase 3 (`onPressed: () {}`).

## Next session (Phase 15 suggestion)
Credits + subscriptions (section 29): the free-download/contribution-
credit system and a subscription plan structure, plus the payment
provider abstraction (section 69) — no real payment processing without
a merchant account, but the same interface + mock pattern used for
every other external service in this codebase.

## What's in this delivery (Phase 15)

**Backend**: `PaymentProvider` interface with a `MockPaymentProvider`
that always succeeds (dev/test only — explicitly documented as never
suitable for a real deployment). `credits/rules.py` — pure functions
for the download-gating check and the contribution-bonus math,
unit-tested first, including multi-threshold crossing (going from 0 to
10 approved contributions in one jump correctly awards *two* bonuses,
not one). A new user gets 3 free credits (lazily granted on first
access); each download spends 1 unless the student has an active
subscription, in which case nothing is spent at all. Subscription
plans read their price from settings rather than hardcoding it into
business logic — the spec explicitly defers the final amount, so the
placeholder is loud (a real UI shows "Price coming soon" for a zero
amount, not a misleading "0 XAF").

**A trigger explicitly NOT wired, and why**: section 29's "contribute 5
approved documents -> earn credits" rule exists as a tested pure
function (`credits_from_new_approvals`), but nothing calls it. No
document can reach "Approved" status without the admin/moderation
workflow — Phase 16, not yet built. Faking a trigger now to exercise
it end-to-end would mean either bypassing real moderation logic or
building a placeholder that Phase 16 would need to rip out; better to
leave the function ready and unwired than to build something that
looks connected but isn't.

**Verified end-to-end**: a full in-memory-SQLite test spending credits
down from 3 to 0 across real downloads, confirming the exact next
download is blocked with a clear message, subscribing and confirming a
download no longer spends any credit at all, canceling and confirming
the block returns, a manual credit grant, and error paths (downloading
a nonexistent past paper, canceling with nothing active to cancel).

**Frontend**: a Credits & Subscription screen (balance, plan list with
the honest placeholder-price display, subscribe action) and a real
download button on past-paper cards — replacing what had only been a
bookmark toggle since Phase 6.

## Next session (Phase 16 suggestion)
Admin/moderation (sections 64-65): the document review queue
(approve/reject/needs-revision), which is also what finally gives
Phase 15's contribution-credit trigger and Phase 6's past-paper file
linkage something real to call.

## What's in this delivery (Phase 16)

**Backend**: `get_current_admin_user` — a dependency gating every admin
endpoint on `User.role == "admin"`, with no in-app path to
self-elevate (role has to be set directly in the database, a
deliberate anti-privilege-escalation choice, not an oversight).
`AdminService` composes existing repositories (documents, catalog,
past_papers, credits, users) rather than duplicating their logic —
approving a document is the exact moment several phases' deferred work
connects:

- **Phase 15's contribution-credit bonus, wired for real.** The
  `credits_from_new_approvals` function — written and unit-tested three
  phases ago with nothing calling it — now runs on every approval,
  counting the uploader's approved documents before and after.
- **Phase 6's "past papers with no linked file" gap, closed.** An
  approved document flagged as an exam paper now creates a real
  `PastPaper` row with an actual `document_id`, using
  `get_or_create_subject_by_name` / `get_or_create_examination` so
  approval never blocks on a missing catalog entry.

The review queue surfaces exactly what a moderator needs by reusing
Phase 5's stored analysis and validation data (detected subject/level
mismatches, duplicate-similarity scores) rather than recomputing
anything.

**Verified end-to-end**, the full loop from upload through the
consequences of approval: a document flagged as an exam paper appears
in the queue with its exam metadata intact; approving it sets status,
awards the *correct* 0 bonus credits (below the 5-contribution
threshold) and creates a real downloadable past paper linked to the
actual document; double-approval is rejected; approving four more
documents from the same student correctly awards 0 credits each time
until the 5th crosses the threshold and awards exactly 5, not partial
credit for partial progress; rejecting a document sets status and
records the reason; analytics counts match; approving a nonexistent
document raises a clean error. Also verified the authorization gate
directly: a student account is blocked with 403, an admin account
passes.

**Frontend**: a review-queue screen — deliberately an internal
moderator tool rather than a consumer-polished screen, since students
never see it. Approve/reject actions with mismatch and duplicate
warnings surfaced inline. A new `currentUserProvider` fetches the
signed-in user's role so the queue's entry point in Profile only
renders for an actual admin account — there's no student-facing way to
even discover the route exists.

## Next session (Phase 17 suggestion)
Security hardening (section 56): rate limiting on auth/upload
endpoints, audit logging for admin actions, input validation review
across all modules, and a pass on what's still missing from "never
expose technical errors" and "never store secrets in the client" now
that every module is built.

## ⚠️ Two more cross-cutting bugs found in this session (not just new features)

Following the practice established in Phase 6 (the UUID-comparison
bug) and Phase 10-11 (extraction/scoring bugs), this phase's security
work led directly to spinning up the **first full end-to-end HTTP
test** of this project — the real FastAPI app, a real in-memory
database, real requests through `TestClient`, rather than calling
services directly. That test surfaced two bugs that every previous
service-level test had missed, because service-level tests never
exercise what a real client actually receives:

**1. `passlib` + `bcrypt` incompatibility (would break registration/
login in any real install).** `passlib==1.7.4` (its last release,
unmaintained since ~2020) is incompatible with `bcrypt>=4.1`, which
removed the `__about__` attribute passlib's backend-detection code
reads. `requirements.txt` never pinned bcrypt's version, so a fresh
`pip install` today pulls bcrypt 5.x and every password hash/verify
crashes with a misleading "password cannot be longer than 72 bytes"
error that has nothing to do with the actual cause. **Fixed** by
pinning `bcrypt>=4.0,<4.1`, verified by actually registering and
logging in a real user through real HTTP calls with real password
hashing — the previous "AuthRepository unit tests" only ever compared
UUIDs and never hashed a real password through the real passlib
context.

**2. Pydantic 2.13 silently broke ~22 response-serialization call
sites across 10 modules.** `SomeSchema.model_validate(orm_object)`
used to auto-coerce a raw `uuid.UUID` attribute into a `str`-typed
Pydantic field; this Pydantic version no longer does, and raises a
validation error instead. Every prior integration test in this project
called a *service* method and asserted on the ORM object or a
hand-built dict it returned — none of them ever asked Pydantic to
serialize that object into the JSON shape a real client receives,
because none of them went through an actual HTTP layer. The very first
real HTTP call in this project's history (`GET /users/me`) failed
immediately. **Fixed** with a shared `orm_to_dict()` helper (converts
UUID columns to strings before Pydantic sees them) applied at all 22
affected call sites across `admin`, `ai_chat`, `catalog`, `credits`,
`documents`, `flashcards`, `notifications`, `planner`,
`study_sessions`, and `users` — then re-verified every one of them via
real HTTP requests, not just re-running the old service-level tests
(which would have kept passing, since they never touched the broken
code path).

**The lesson, stated plainly for future phases**: service-layer
integration tests (this project's standard since Phase 6) verify
*business logic* correctness. They cannot verify *serialization*
correctness, because Pydantic validation only runs when a router
actually calls `.model_validate()` — and every test so far bypassed
the router layer entirely. From this phase forward, any new
`GET`/list endpoint should get at least one real HTTP-level check
(TestClient or equivalent), not only a service-level one.

## What's in this delivery (Phase 17)

**Rate limiting**: `slowapi`-based limits on `/auth/register`,
`/auth/login`, `/auth/password/forgot` (5-10/minute), and
`/documents/upload` (10/minute), with a custom 429 handler matching
this codebase's own error envelope rather than slowapi's default shape
— verified by actually hammering `/auth/register` past its limit
through real HTTP calls and confirming the exact response shape.

**Audit logging**: a new `audit_logs` table (from the original Phase 1
DB schema, unused until now) recording every admin approve/reject
action with actor, target, and outcome detail. A new
`GET /admin/audit-log` endpoint to read it back.

**Input validation hardening**: chat messages capped at 4000 chars,
document descriptions capped at 50,000 chars (defense-in-depth ahead
of the 500-word *minimum* check), past-paper search queries capped at
200 chars, and — a real gap — voice/vision uploads had **no size limit
at all** before this phase; now capped at 15MB/10MB respectively.

**Startup safety check**: the app now refuses to start outside debug
mode if `SECRET_KEY` is still the placeholder value from
`.env.example` — tested directly (raises in the unsafe case, silent in
every safe case) rather than only hoped for.

**Security headers**: `X-Content-Type-Options`, `X-Frame-Options`,
`Referrer-Policy` on every response, verified present via real HTTP
responses.

## Next session (Phase 18 suggestion)
Testing (section 78): formalize the ad-hoc integration tests written
throughout this project into a real pytest suite that runs in CI,
including the end-to-end HTTP pattern this phase introduced — plus
Flutter widget tests for the screens that have accumulated real logic
(chat, quiz-taking, the onboarding flow).

## What's in this delivery (Phase 18)

**A real, running pytest suite** — `backend/tests/`, 46 tests, all
passing — replacing the ad-hoc bash-heredoc integration tests scattered
across this conversation's history with a proper suite anyone can run
via `pytest`. `conftest.py` provides a fresh in-memory database per
test, a `TestClient` wired to the real app, and fixtures for a
registered user and an admin user (elevated by direct DB write, since
no in-app path exists). An autouse fixture resets slowapi's rate-limit
state before every test — without it, the ~15 tests that each register
a user would share global rate-limit state and fail for reasons
unrelated to what they're individually checking.

**Coverage**: `test_pure_functions.py` exercises one representative
case from every module's business logic in milliseconds (the pronoun
filter, the gameable-quiz-position check, the quiet-hours midnight
wrap, the readiness-score honesty case, and more — the specific
assertions that caught real bugs across Phases 5-17, now permanent
regression tests). The remaining files (`test_auth`, `test_documents`,
`test_ai_chat`, `test_planner`, `test_flashcards_quizzes`,
`test_notifications_credits`, `test_admin`, `test_security`) exercise
the same scenarios through real HTTP requests, per Phase 17's finding
that only the router layer can catch a serialization bug.

**Two more test-fixture bugs found and fixed while assembling this
suite** — in my own tests, not the application:
1. A test description built from a repeated sentence tripped the
   Phase 4 spam filter (correctly) — the test's fixture was wrong, not
   the filter. Fixed with a shared `make_valid_description()` helper
   generating genuinely varied text.
2. Tests using placeholder bytes like `b"%PDF-1.4 fake pdf"` as upload
   content correctly got rejected by Phase 5's real PDF parser as
   unreadable. Fixed with `make_valid_pdf_bytes()`, generating an
   actual minimal PDF via `pypdf.PdfWriter` — the same technique
   Phase 5 used when it first verified the extraction pipeline.

Neither was a bug in the app; both are exactly the kind of thing a
test suite should have found before being trusted, and did.

**Frontend**: three widget-test files for the screens with real,
UI-independent logic — `ChatBubble`'s course-material tag visibility
(including a guard against a copy-paste bug where the tag might show
on a user's own message), `OnboardingStepScaffold`'s progress bar math
and button enable/disable states, and `QuizResultsScreen`'s per-
question correct/incorrect rendering. **Honestly caveated**: this
sandbox has no Flutter SDK, so — consistent with every other Flutter
file across all 18 phases — these are written to real Flutter test
conventions and syntax/brace-balance checked, but not executed. Run
`flutter test` locally to confirm.

## Next session (Phase 19 suggestion)
Android release build (section 20): app icon/splash generation from
the brand config, a release-mode `build.gradle` review, and the
first real `flutter build apk --release` — the first point in this
whole project where the Flutter side needs to actually compile, not
just be syntax-checked.

## What's in this delivery (Phase 19)

**Confirmed, not assumed, that a real Flutter build can't run here.**
Rather than guessing at the sandbox's limitations, I tested them
directly: cloning `flutter/flutter` from GitHub succeeds (`github.com`
is reachable), but `flutter --version` fails at the Dart-SDK-download
step because that download goes to `storage.googleapis.com`, which
isn't reachable from this environment. This means **no Dart/Flutter
file across all 19 phases of this project has ever been compiled** —
every one was written to correct syntax and brace-balance checked,
never run through `dartanalyzer` or the Flutter compiler. Worth
stating plainly rather than letting 18 phases of "syntax OK" checks be
mistaken for "compiles cleanly."

**What this phase actually built, since a real build wasn't possible**:
the entire `android/` native platform directory, by hand — it never
existed until now, since `flutter create` (which normally generates
it) was never runnable either.

- `android/app/build.gradle`: real signing-config wiring (falls back
  to the debug key when no `key.properties` exists yet, so a local
  build works before a real upload keystore is generated — but never
  silently ships a debug-signed release), version code/name read from
  `local.properties` the way Flutter's own template does, R8/ProGuard
  enabled for release, `minSdkVersion 23` chosen for compatibility
  with this project's actual plugin set (`record`, `image_picker`,
  `audioplayers`).
- `AndroidManifest.xml`: scoped to exactly what this app uses —
  `INTERNET`, `RECORD_AUDIO` (Phase 13's voice input), `CAMERA` (Phase
  13's vision input), with the camera hardware feature marked
  *not required* since vision mode is an enhancement, not a hard
  dependency. Validated as well-formed XML (Python's `xml.etree`,
  since no Android tooling is available to validate it more deeply).
- `flutter_launcher_icons`/`flutter_native_splash` configuration wired
  to the same `BrandConfig` asset paths the app itself already reads
  from — the icon/splash images don't exist yet (section 70's
  branding is still a placeholder by design), but generating them is
  now a two-command step once real assets are dropped in.
- `docs/ANDROID_RELEASE.md`: the exact steps — install Flutter, first-
  time setup, generate a real signing keystore, replace placeholder
  branding, build, and a real-device sanity checklist — written for
  the person who runs this on an actual machine with a working Flutter
  install, since I can't verify past this point myself.

**Every file added this phase was validated the ways actually
available**: all Android XML confirmed well-formed, all `.gradle`
files brace-balanced, `pubspec.yaml` re-confirmed valid YAML after the
new dev-dependency blocks, and the full backend pytest suite (46
tests) and all 111 Dart files re-checked to confirm nothing regressed.

## Next session (Phase 20 suggestion)
Windows release build (section 21): the `windows/` platform directory
(same "never existed, build by hand" situation as this phase's
`android/`), a release-mode CMake/MSVC configuration review, and the
same honest documentation of what can and can't be verified without a
Windows machine and a working Flutter desktop install.

## What's in this delivery (Phase 20 + logo integration)

**Your logo is now the app's real branding**, not a placeholder:
saved at `assets/brand/icon.png` and `assets/brand/splash.png` (the
exact paths `core/theme/brand_config.dart` and the
`flutter_launcher_icons`/`flutter_native_splash` config from Phase 19
already expected), declared in `pubspec.yaml`'s asset list, and
verified to load correctly (converted to RGBA, confirmed valid PNG).
Running `dart run flutter_launcher_icons` and
`dart run flutter_native_splash:create` locally will now generate real
Android (and, once `windows/runner/` exists — see below — Windows)
icons from it instead of Flutter's default.

**Windows got deliberately less hand-written scaffolding than
Android did, and here's the honest reason**: Android's platform files
(Gradle, XML) are declarative enough that I could actually validate
them — well-formed XML, balanced braces. Windows desktop's platform
folder is mostly generated Win32/CMake **C++** source, which I cannot
compile or meaningfully check here. Hand-transcribing Win32 window-
management boilerplate from memory and presenting it as done would be
worse than not writing it — wrong C++ fails in ways far harder to
debug than a missing XML tag. So this phase writes only the
declarative top-level `windows/CMakeLists.txt` and documents the one
safe path for the rest: running `flutter create --platforms=windows .`
locally, which regenerates exactly those files deterministically from
the official template without touching any Dart code already written.

With this, all 20 phases of the original master-spec roadmap are
built out at the level a sandboxed code environment can honestly
reach. What's left — real compilation, real device/browser testing,
final branding/pricing/legal decisions, and real app-store submission
— needs a real machine and real accounts, not more code.
