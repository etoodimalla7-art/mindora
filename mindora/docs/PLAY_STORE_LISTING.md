# MINDORA — Google Play Store Listing & Compliance Package

## 1. Metadata & Categorization
- **Package Name**: `com.mindora.app`
- **Category**: Education
- **Target Audience**: Secondary & University Students (Ages 13+, GCE O/A-Level, BEPC, Probatoire, Baccalauréat, HND, BTS, Licence)
- **Content Rating**: PEGI 3 / Everyone
- **Languages Supported**: English (`en`), Français (`fr`)
- **Privacy Policy URL**: `https://mindora.dev/privacy`
- **Terms of Service URL**: `https://mindora.dev/terms`
- **Support Email / Portal**: `https://mindora.dev/contact` (and in-app Support Tickets)

---

## 2. Store Listing — English (`en-US` / `en-GB`)
### App Name (max 30 chars)
`MINDORA: AI Exam Prep & Tutor`

### Short Description (max 80 chars)
`Master GCE, BEPC, Bac & HND with AI tutoring, past papers, SM-2 & mock exams.`

### Full Description
Stop wondering what to study next. **MINDORA** turns your curriculum into a clear daily plan so you know **what to study, why, how, and whether you're ready**.

Built specifically for Cameroonian and Pan-African students preparing for **GCE O-Level, GCE A-Level, BEPC, Probatoire, Baccalauréat, HND, BTS, Licence, and Master** exams.

**Key Features:**
- **Smart Study Planner**: Exam countdown roadmaps tailored to your subjects and available study windows.
- **Bilingual AI Tutor (FR + EN)**: Live streaming explanations, step-by-step math help, photo exercise solver, voice tutor, and RAG search grounded in approved course documents.
- **Past Papers Library (PDF)**: Browse, filter by system/level/year, download, and read past exam papers offline in-app.
- **SM-2 Spaced Repetition Flashcards**: Scientifically timed review decks + AI flashcard generation.
- **Timed Mock Exams**: Server-graded practice tests with topic mastery breakdown and detailed corrections.
- **Live Study Groups**: Collaborate in real time with fellow students preparing for the same exam.
- **Offline-First Sync**: Review downloaded papers, study plans, and flashcards offline; sync automatically when back online.

---

## 3. Store Listing — Français (`fr-FR`)
### Nom de l'application
`MINDORA : Prépa Examens & IA`

### Description courte
`Réussis GCE, BEPC, Bac & BTS : tuteur IA, annales PDF, flashcards SM-2 et quiz.`

### Description complète
Ne te demande plus quoi réviser aujourd'hui. **MINDORA** transforme ton programme en un parcours quotidien clair : **quoi étudier, pourquoi, comment, et si tu es prêt pour le jour J**.

Conçu pour les élèves et étudiants préparant : **BEPC, Probatoire, Baccalauréat, GCE O-Level, GCE A-Level, BTS, HND, Licence et Master**.

**Fonctionnalités clés :**
- **Planning Intelligent** : Compte à rebours d'examen et sessions quotidiennes adaptées à tes matières.
- **Tuteur IA Bilingue (FR + EN)** : Réponses en streaming temps réel, analyse de photos d'exercices, mode vocal et recherche dans tes cours.
- **Bibliothèque d'Annales (PDF)** : Filtre par système, niveau et année, télécharge et lis les sujets hors ligne.
- **Flashcards Répétition Espacée (SM-2)** : Mémorisation optimisée et génération assistée par IA.
- **Examens Blancs Chronométrés** : Épreuves corrigées côté serveur avec diagnostic par chapitre.
- **Groupes d'Étude en Direct** : Entraide en temps réel avec les étudiants de ta filière.

---

## 4. Google Play Data Safety Declaration
- **Data collected & purpose**:
  - *Personal info (Name, Email)*: Account creation, authentication, email OTP verification, support tickets (encrypted in transit via HTTPS/TLS; JWT stored locally with Android `EncryptedSharedPreferences` AES-256-GCM).
  - *App activity & academic progress*: Study plans, flashcard intervals, mock exam answers, AI tutor history (used exclusively for personalized learning analytics).
  - *User-uploaded files & photos*: Study notes uploaded by student, optional exercise photos sent to AI Vision endpoint.
  - *Purchase history*: Subscription tier & Flutterwave transaction reference (card/Mobile Money details handled directly inside Flutterwave Checkout, never stored by MINDORA).
- **Data sharing**: No data sold or shared with third-party advertisers.
- **Account deletion**: Supported via in-app/API account deletion workflow (`/api/v1/users/me/delete`) with scheduled purge.

---

## 5. Release Build & Signing Checklist
1. Generate upload keystore locally (never commit keystore/passwords to git):
   ```bash
   keytool -genkey -v -keystore mindora-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mindora
   ```
2. Build signed AAB with R8 minification enabled and production API URL:
   ```bash
   ./gradlew bundleRelease -PMINDORA_API_URL=https://mindora-w3jv.onrender.com/api/v1/
   ```
3. Upload `app/build/outputs/bundle/release/app-release.aab` to Google Play Console Internal Testing track.
