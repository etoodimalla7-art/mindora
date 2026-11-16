# MINDORA

AI-powered exam-preparation platform built with React, TypeScript, Tailwind CSS, Express, and the `@google/genai` SDK.

## Features

- **Home Dashboard**: Exam countdown, daily study streak, today's focus session, 6-dimension exam readiness ring, weak topics tracker, and quick actions.
- **Course-Grounded AI Tutor**: Multi-turn Gemini tutor (`gemini-4-hydrogen`) that searches your approved course notes first, cites matching documents, supports Socratic mode, math calculation, exercise image upload (vision), voice input, and text-to-speech playback.
- **Study Planner & Focused Session Timer**: Exam-mode and subject-mode roadmap generator, pending session rescheduling, and distraction-free countdown timer with AI tutor handoff.
- **Learning Tools**:
  - **Past Papers Library**: Cascading filters (system, level, subject), search, bookmarks, and credit-gated downloads.
  - **Document Contribution & Validation**: Live 500-word description validator, spam-repetition check, language mismatch detection, subject classification, and duplicate similarity check.
  - **Flashcards**: SM-2 spaced repetition review (Hard / Good / Easy) and extractive or AI-generated decks.
  - **Quizzes & Timed Mock Exams**: Multi-subject timed mock exams with countdown auto-submission, weighted subject breakdowns, and detailed per-question corrections.
- **Credits, Subscriptions, Notifications & Moderation**: Download credits ledger, +5 credit milestone bonus per 5 approved contributions, quiet-hours notification settings, bilingual EN/FR UI, light/dark mode, and a Moderator review queue.

## Running Locally

```bash
npm install
npm run dev
```

The server listens on `http://0.0.0.0:3000`. Set `GEMINI_API_KEY` in your environment or `.env` for live AI tutoring.
