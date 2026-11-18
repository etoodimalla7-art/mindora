# MINDORA — Android (Kotlin + Jetpack Compose)

AI-powered exam-preparation platform rewritten as a native Android application using Kotlin, Jetpack Compose, and Material 3.

## Features
- **Onboarding & Academic Profile**: Multi-step setup for language (English / Français), country, education system (Anglophone / Francophone), level (GCE O/A Level, BEPC, Bac, HND, Licence, Master), subjects, study goals, and AI explanation style.
- **Dashboard & Study Focus**: Exam countdown, study streak tracking, today's focus session with live study timer, exam readiness ring breakdown, weak topics, and quick actions.
- **AI Tutor**: Conversation history, clickable sample prompts, built-in arithmetic/scientific evaluator, local course document RAG search, and optional Gemini API integration via `.env` (`GEMINI_API_KEY`).
- **Study Planner**: Create exam or subject plans with generated topic roadmaps and mark sessions completed.
- **Learn Hub**:
  - **Past Papers**: Filter by system and level, unlock papers with download credits, and preview sample questions.
  - **Flashcards**: Deck management, AI card generation, and SM-2 spaced repetition review.
  - **Mock Exams**: Timed MCQ / True-False exams with score ring, topic breakdown, and detailed corrections.
  - **Contributions**: Upload study notes/documents (indexed for AI Tutor RAG) to earn download credits.
- **Profile, Study Groups & Settings**: Peer study group chat, appearance modes (System / Light / Dark), and language switching.

## Build
```bash
gradle assembleDebug
```
APK output: `app/build/outputs/apk/debug/app-debug.apk`
