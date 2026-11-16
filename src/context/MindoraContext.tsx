import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import {
  CATALOG_TOPICS_BY_SUBJECT,
  INITIAL_DECKS,
  INITIAL_DOCUMENTS,
  INITIAL_FLASHCARDS,
  INITIAL_PAST_PAPERS,
  INITIAL_PLANS,
  INITIAL_QUIZ_ATTEMPTS,
  INITIAL_QUIZZES,
  INITIAL_SESSIONS,
  INITIAL_USER,
} from '../data/seedData';
import {
  analyzeDocumentSubmission,
  buildSessionPlan,
  computeStudyStreak,
  computeXpLevelInfo,
  creditsFromNewApprovals,
  deriveGamificationFromHistory,
  formatLocalDateKey,
  generateExtractiveFlashcards,
  generateExtractiveQuizQuestions,
  isQuietHours,
  reschedulePendingSessions,
  updateSm2,
} from '../lib/mindoraEngine';
import type {
  AppTab,
  Conversation,
  CreditTransaction,
  DocumentItem,
  EducationProfile,
  Flashcard,
  FlashcardDeck,
  LanguageCode,
  MockExam,
  MockExamAttempt,
  NotificationItem,
  NotificationPreferences,
  PastPaper,
  Quiz,
  QuizAttempt,
  StudyPlan,
  StudySessionItem,
  StudyStreakInfo,
  SubView,
  ThemeMode,
  UserProfile,
  UserRole,
  XpCategory,
  XpEvent,
  XpLevelInfo,
} from '../types/mindora';

interface PersistedState {
  user: UserProfile | null;
  theme: ThemeMode;
  language: LanguageCode;
  plans: StudyPlan[];
  sessions: StudySessionItem[];
  documents: DocumentItem[];
  pastPapers: PastPaper[];
  decks: FlashcardDeck[];
  flashcards: Flashcard[];
  quizzes: Quiz[];
  quizAttempts: QuizAttempt[];
  mockExams: MockExam[];
  mockExamAttempts: MockExamAttempt[];
  conversations: Conversation[];
  activeConversationId: string | null;
  creditsBalance: number;
  creditHistory: CreditTransaction[];
  activeSubscriptionCode: string | null;
  notifications: NotificationItem[];
  notificationPrefs: NotificationPreferences;
  xpEvents: XpEvent[];
  activityDates: string[];
}

const STORAGE_KEY = 'mindora_web_state_v1';

function createInitialState(): PersistedState {
  const initialGamification = deriveGamificationFromHistory({
    sessions: INITIAL_SESSIONS,
    quizAttempts: INITIAL_QUIZ_ATTEMPTS,
    mockExamAttempts: [],
    documents: INITIAL_DOCUMENTS,
    flashcards: INITIAL_FLASHCARDS,
    userId: INITIAL_USER.id,
  });

  return {
    user: INITIAL_USER,
    theme: 'light',
    language: 'en',
    plans: INITIAL_PLANS,
    sessions: INITIAL_SESSIONS,
    documents: INITIAL_DOCUMENTS,
    pastPapers: INITIAL_PAST_PAPERS,
    decks: INITIAL_DECKS,
    flashcards: INITIAL_FLASHCARDS,
    quizzes: INITIAL_QUIZZES,
    quizAttempts: INITIAL_QUIZ_ATTEMPTS,
    mockExams: [],
    mockExamAttempts: [],
    conversations: [
      {
        id: 'conv-initial',
        title: 'Differential Equations Help',
        stylePreferences: {},
        updatedAt: new Date().toISOString(),
        messages: [],
      },
    ],
    activeConversationId: 'conv-initial',
    creditsBalance: 3,
    creditHistory: [
      {
        id: 'cr-welcome',
        delta: 3,
        reason: 'Welcome free download credits',
        createdAt: new Date(Date.now() - 6 * 86400000).toISOString(),
      },
    ],
    activeSubscriptionCode: null,
    notifications: [
      {
        id: 'notif-1',
        type: 'session_upcoming',
        title: 'Today’s study session is ready',
        body: 'First-Order Differential Equations & Integrating Factors (45 min).',
        read: false,
        createdAt: new Date(Date.now() - 2 * 3600000).toISOString(),
        dedupKey: 'today-sess-1',
      },
      {
        id: 'notif-2',
        type: 'exam_countdown',
        title: 'GCE Advanced Level 2027 countdown',
        body: 'Stay consistent with your daily Mathematics & Physics blocks.',
        read: false,
        createdAt: new Date(Date.now() - 12 * 3600000).toISOString(),
        dedupKey: 'countdown-gce',
      },
    ],
    notificationPrefs: {
      enabled: true,
      quietStartHour: 22,
      quietEndHour: 7,
    },
    xpEvents: initialGamification.xpEvents,
    activityDates: initialGamification.activityDates,
  };
}

function loadState(): PersistedState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return createInitialState();
    const parsed = JSON.parse(raw) as Partial<PersistedState>;
    const defaults = createInitialState();
    const merged: PersistedState = { ...defaults, ...parsed };

    // Backfill gamification fields cleanly if upgrading from an older saved state
    if (!Array.isArray(parsed.xpEvents) || !Array.isArray(parsed.activityDates)) {
      const derived = deriveGamificationFromHistory({
        sessions: merged.sessions,
        quizAttempts: merged.quizAttempts,
        mockExamAttempts: merged.mockExamAttempts,
        documents: merged.documents,
        flashcards: merged.flashcards,
        userId: merged.user?.id,
      });
      if (!Array.isArray(parsed.xpEvents)) merged.xpEvents = derived.xpEvents;
      if (!Array.isArray(parsed.activityDates)) merged.activityDates = derived.activityDates;
    }

    return merged;
  } catch {
    return createInitialState();
  }
}

interface MindoraContextValue extends PersistedState {
  activeTab: AppTab;
  subView: SubView;
  pendingAiPrompt: string | null;
  setActiveTab: (tab: AppTab) => void;
  setSubView: (view: SubView) => void;
  navigate: (tab: AppTab, view?: SubView) => void;
  setTheme: (theme: ThemeMode) => void;
  setLanguage: (lang: LanguageCode) => void;
  toggleRole: (role: UserRole) => void;
  signOut: () => void;
  signInDemo: () => void;
  registerOrSignIn: (payload: { fullName: string; email: string }) => void;
  completeOnboarding: (profile: EducationProfile, lang: LanguageCode) => void;
  resetDemoWorkspace: () => void;

  // Planner & Sessions
  createStudyPlan: (payload: {
    planType: 'exam' | 'subject';
    title: string;
    targetExamName?: string;
    targetDate: string;
    subjects: string[];
    dailyMinutes: number;
  }) => StudyPlan;
  reschedulePlan: (planId: string) => void;
  completeSession: (sessionId: string) => void;
  skipSession: (sessionId: string) => void;
  handoffToAiTutor: (prompt: string) => void;
  clearPendingAiPrompt: () => void;

  // Documents & Moderation
  submitDocument: (payload: {
    title: string;
    subject: string;
    educationSystem: string;
    level: string;
    language: LanguageCode;
    fileName: string;
    isExamPaper: boolean;
    examYear?: number;
    examSession?: string;
    description: string;
    contentText: string;
  }) => DocumentItem;
  moderateDocument: (docId: string, decision: 'approved' | 'rejected' | 'needs_revision', reason?: string) => void;

  // Past Papers & Credits
  toggleBookmarkPaper: (paperId: string) => void;
  downloadPastPaper: (paperId: string) => { ok: boolean; message: string };

  // Flashcards
  createFlashcardDeck: (payload: { title: string; subject: string; sourceText: string; cards?: Array<{ front: string; back: string }> }) => FlashcardDeck;
  reviewFlashcard: (cardId: string, quality: number) => void;

  // Quizzes
  createQuiz: (payload: { title: string; subject: string; difficulty: 'easy' | 'medium' | 'hard'; sourceText: string; questions?: Quiz['questions'] }) => Quiz;
  submitQuizAttempt: (quizId: string, answers: Record<string, number>) => QuizAttempt;

  // Mock Exams
  createMockExam: (payload: { title: string; subjects: string[]; questionsPerSubject: number; durationMinutes: number; difficulty: 'easy' | 'medium' | 'hard' }) => MockExam;
  startMockExam: (examId: string) => void;
  submitMockExam: (examId: string, answers: Record<string, number>) => MockExamAttempt;

  // AI Conversations
  setActiveConversationId: (id: string) => void;
  createConversation: () => string;
  updateConversation: (conv: Conversation) => void;

  // Notifications & Subscriptions
  markNotificationRead: (id: string) => void;
  markAllNotificationsRead: () => void;
  updateNotificationPrefs: (prefs: NotificationPreferences) => void;
  subscribeToPlan: (planCode: string) => void;
  cancelSubscription: () => void;

  // Study Streak & XP Level
  xpLevel: XpLevelInfo;
  studyStreak: StudyStreakInfo;
  claimDailyCheckIn: () => boolean;
}

const MindoraContext = createContext<MindoraContextValue | null>(null);

export const MindoraProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, setState] = useState<PersistedState>(() => loadState());
  const [activeTab, setActiveTabState] = useState<AppTab>('home');
  const [subView, setSubView] = useState<SubView>({ type: 'none' });
  const [pendingAiPrompt, setPendingAiPrompt] = useState<string | null>(null);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch {
      // ignore storage quota errors
    }
  }, [state]);

  useEffect(() => {
    const root = document.documentElement;
    if (state.theme === 'dark') {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  }, [state.theme]);

  const setActiveTab = useCallback((tab: AppTab) => {
    setActiveTabState(tab);
    setSubView({ type: 'none' });
  }, []);

  const navigate = useCallback((tab: AppTab, view: SubView = { type: 'none' }) => {
    setActiveTabState(tab);
    setSubView(view);
  }, []);

  const setTheme = useCallback((theme: ThemeMode) => {
    setState((prev) => ({ ...prev, theme }));
  }, []);

  const setLanguage = useCallback((language: LanguageCode) => {
    setState((prev) => ({
      ...prev,
      language,
      user: prev.user ? { ...prev.user, preferredLanguage: language } : prev.user,
    }));
  }, []);

  const toggleRole = useCallback((role: UserRole) => {
    setState((prev) => ({
      ...prev,
      user: prev.user ? { ...prev.user, role } : prev.user,
    }));
  }, []);

  const signOut = useCallback(() => {
    setState((prev) => ({ ...prev, user: null }));
    setSubView({ type: 'none' });
  }, []);

  const signInDemo = useCallback(() => {
    setState((prev) => ({ ...prev, user: INITIAL_USER }));
  }, []);

  const registerOrSignIn = useCallback((payload: { fullName: string; email: string }) => {
    setState((prev) => ({
      ...prev,
      user: {
        ...INITIAL_USER,
        id: `usr-${Date.now()}`,
        fullName: payload.fullName.trim() || 'Student',
        email: payload.email.trim(),
        onboardingCompleted: false,
      },
      plans: [],
      sessions: [],
      quizAttempts: [],
      mockExams: [],
      mockExamAttempts: [],
      creditsBalance: 3,
      xpEvents: [],
      activityDates: [],
    }));
  }, []);

  const completeOnboarding = useCallback((profile: EducationProfile, lang: LanguageCode) => {
    setState((prev) => ({
      ...prev,
      language: lang,
      user: prev.user
        ? {
            ...prev.user,
            preferredLanguage: lang,
            onboardingCompleted: true,
            educationProfile: profile,
          }
        : null,
      notificationPrefs: {
        ...prev.notificationPrefs,
        enabled: profile.notificationsEnabled,
      },
    }));
  }, []);

  const resetDemoWorkspace = useCallback(() => {
    const fresh = createInitialState();
    setState(fresh);
    setActiveTabState('home');
    setSubView({ type: 'none' });
  }, []);

  const createStudyPlan = useCallback(
    (payload: {
      planType: 'exam' | 'subject';
      title: string;
      targetExamName?: string;
      targetDate: string;
      subjects: string[];
      dailyMinutes: number;
    }): StudyPlan => {
      const planId = `plan-${Date.now()}`;
      const newPlan: StudyPlan = {
        id: planId,
        title: payload.title,
        planType: payload.planType,
        targetExamName: payload.targetExamName,
        targetDate: payload.targetDate,
        subjects: payload.subjects,
        dailyMinutes: payload.dailyMinutes,
        createdAt: new Date().toISOString(),
      };
      const today = new Date().toISOString().slice(0, 10);
      const generatedSessions = buildSessionPlan({
        planId,
        subjects: payload.subjects,
        topicsBySubject: CATALOG_TOPICS_BY_SUBJECT,
        startDate: today,
        targetDate: payload.targetDate,
        dailyMinutes: payload.dailyMinutes,
      });

      setState((prev) => ({
        ...prev,
        plans: [newPlan, ...prev.plans],
        sessions: [...generatedSessions, ...prev.sessions],
      }));
      return newPlan;
    },
    []
  );

  const reschedulePlan = useCallback((planId: string) => {
    const today = new Date().toISOString().slice(0, 10);
    setState((prev) => ({
      ...prev,
      sessions: reschedulePendingSessions(prev.sessions, planId, today),
    }));
  }, []);

  const appendActivityAndXp = (
    prev: PersistedState,
    amount: number,
    reason: string,
    category: XpCategory
  ): { xpEvents: XpEvent[]; activityDates: string[] } => {
    const todayKey = formatLocalDateKey();
    const nextDates = prev.activityDates.includes(todayKey)
      ? prev.activityDates
      : [...prev.activityDates, todayKey].sort();
    const event: XpEvent = {
      id: `xp-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
      amount,
      reason,
      category,
      createdAt: new Date().toISOString(),
    };
    return {
      xpEvents: [event, ...prev.xpEvents],
      activityDates: nextDates,
    };
  };

  const completeSession = useCallback((sessionId: string) => {
    setState((prev) => {
      const target = prev.sessions.find((s) => s.id === sessionId);
      if (!target || target.status === 'completed') return prev;
      const gamification = appendActivityAndXp(
        prev,
        50,
        `Completed session: ${target.title}`,
        'session'
      );
      return {
        ...prev,
        sessions: prev.sessions.map((s) =>
          s.id === sessionId ? { ...s, status: 'completed', completedAt: new Date().toISOString() } : s
        ),
        ...gamification,
      };
    });
  }, []);

  const skipSession = useCallback((sessionId: string) => {
    setState((prev) => ({
      ...prev,
      sessions: prev.sessions.map((s) => (s.id === sessionId ? { ...s, status: 'skipped' } : s)),
    }));
  }, []);

  const handoffToAiTutor = useCallback((prompt: string) => {
    setPendingAiPrompt(prompt);
    setActiveTabState('ai');
    setSubView({ type: 'none' });
  }, []);

  const clearPendingAiPrompt = useCallback(() => setPendingAiPrompt(null), []);

  const submitDocument = useCallback(
    (payload: {
      title: string;
      subject: string;
      educationSystem: string;
      level: string;
      language: LanguageCode;
      fileName: string;
      isExamPaper: boolean;
      examYear?: number;
      examSession?: string;
      description: string;
      contentText: string;
    }): DocumentItem => {
      const analysis = analyzeDocumentSubmission(payload, state.documents);
      const status = analysis.problems.length > 0 ? 'needs_revision' : 'under_review';
      const newDoc: DocumentItem = {
        id: `doc-${Date.now()}`,
        ...payload,
        status,
        uploaderId: state.user?.id ?? 'usr-demo-1',
        uploaderName: state.user?.fullName ?? 'Student',
        createdAt: new Date().toISOString(),
        analysis,
      };
      setState((prev) => {
        const gamification = appendActivityAndXp(
          prev,
          30,
          `Contributed document: ${payload.title}`,
          'document'
        );
        return {
          ...prev,
          documents: [newDoc, ...prev.documents],
          ...gamification,
        };
      });
      return newDoc;
    },
    [state.documents, state.user]
  );

  const moderateDocument = useCallback(
    (docId: string, decision: 'approved' | 'rejected' | 'needs_revision', reason?: string) => {
      setState((prev) => {
        const target = prev.documents.find((d) => d.id === docId);
        if (!target) return prev;

        const prevApprovedByUploader = prev.documents.filter(
          (d) => d.uploaderId === target.uploaderId && d.status === 'approved'
        ).length;

        const updatedDocs = prev.documents.map((d) =>
          d.id === docId
            ? { ...d, status: decision, rejectionReason: decision === 'approved' ? undefined : reason }
            : d
        );

        let nextCredits = prev.creditsBalance;
        const nextHistory = [...prev.creditHistory];
        const nextNotifs = [...prev.notifications];
        let nextPastPapers = [...prev.pastPapers];

        if (decision === 'approved') {
          const newApprovedByUploader = updatedDocs.filter(
            (d) => d.uploaderId === target.uploaderId && d.status === 'approved'
          ).length;

          const bonus = creditsFromNewApprovals(prevApprovedByUploader, newApprovedByUploader);
          if (bonus > 0 && target.uploaderId === prev.user?.id) {
            nextCredits += bonus;
            nextHistory.unshift({
              id: `cr-${Date.now()}`,
              delta: bonus,
              reason: `5-contribution milestone bonus (${target.title})`,
              createdAt: new Date().toISOString(),
            });
          }

          if (target.isExamPaper) {
            const alreadyLinked = nextPastPapers.some((p) => p.documentId === target.id);
            if (!alreadyLinked) {
              nextPastPapers.unshift({
                id: `pp-doc-${target.id}`,
                title: target.title,
                country: prev.user?.educationProfile.country || 'Cameroon',
                system: target.educationSystem,
                level: target.level,
                subject: target.subject,
                year: target.examYear || new Date().getFullYear(),
                session: target.examSession || 'June',
                summary: target.description.slice(0, 180) + '...',
                bookmarked: false,
                downloaded: false,
                documentId: target.id,
              });
            }
          }

          const hour = new Date().getHours();
          if (
            prev.notificationPrefs.enabled &&
            !isQuietHours(hour, prev.notificationPrefs.quietStartHour, prev.notificationPrefs.quietEndHour)
          ) {
            nextNotifs.unshift({
              id: `notif-mod-${Date.now()}`,
              type: 'moderation',
              title: 'Document approved',
              body: `"${target.title}" is now approved and indexed for AI tutoring.${bonus > 0 ? ` +${bonus} bonus credits awarded!` : ''}`,
              read: false,
              createdAt: new Date().toISOString(),
            });
          }
        }

        return {
          ...prev,
          documents: updatedDocs,
          creditsBalance: nextCredits,
          creditHistory: nextHistory,
          notifications: nextNotifs,
          pastPapers: nextPastPapers,
        };
      });
    },
    []
  );

  const toggleBookmarkPaper = useCallback((paperId: string) => {
    setState((prev) => ({
      ...prev,
      pastPapers: prev.pastPapers.map((p) => (p.id === paperId ? { ...p, bookmarked: !p.bookmarked } : p)),
    }));
  }, []);

  const downloadPastPaper = useCallback(
    (paperId: string): { ok: boolean; message: string } => {
      const paper = state.pastPapers.find((p) => p.id === paperId);
      if (!paper) return { ok: false, message: 'Past paper not found.' };

      const hasSub = Boolean(state.activeSubscriptionCode);
      if (!paper.downloaded && !hasSub && state.creditsBalance <= 0) {
        return {
          ok: false,
          message: 'You have 0 download credits remaining. Contribute an approved document or subscribe to unlock unlimited downloads.',
        };
      }

      // Generate a clean offline text/study sheet download for the past paper
      const content = [
        `MINDORA PAST PAPER — ${paper.title}`,
        `System: ${paper.system} | Level: ${paper.level} | Subject: ${paper.subject} | Year: ${paper.year}`,
        paper.session ? `Session: ${paper.session}` : '',
        '',
        'Summary & Scope:',
        paper.summary,
        '',
        'Use the MINDORA AI Tutor or Mock Exam generator to practice questions from this syllabus.',
      ]
        .filter(Boolean)
        .join('\n');

      const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${paper.title.toLowerCase().replace(/[^a-z0-9]+/g, '_')}.txt`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);

      if (!paper.downloaded && !hasSub) {
        setState((prev) => ({
          ...prev,
          creditsBalance: Math.max(0, prev.creditsBalance - 1),
          creditHistory: [
            {
              id: `cr-${Date.now()}`,
              delta: -1,
              reason: `Downloaded ${paper.title}`,
              createdAt: new Date().toISOString(),
            },
            ...prev.creditHistory,
          ],
          pastPapers: prev.pastPapers.map((p) => (p.id === paperId ? { ...p, downloaded: true } : p)),
        }));
      } else {
        setState((prev) => ({
          ...prev,
          pastPapers: prev.pastPapers.map((p) => (p.id === paperId ? { ...p, downloaded: true } : p)),
        }));
      }

      return { ok: true, message: `Downloaded "${paper.title}".` };
    },
    [state.pastPapers, state.activeSubscriptionCode, state.creditsBalance]
  );

  const createFlashcardDeck = useCallback(
    (payload: {
      title: string;
      subject: string;
      sourceText: string;
      cards?: Array<{ front: string; back: string }>;
    }): FlashcardDeck => {
      const deckId = `deck-${Date.now()}`;
      const newDeck: FlashcardDeck = {
        id: deckId,
        title: payload.title,
        subject: payload.subject,
        createdAt: new Date().toISOString(),
      };
      const nowIso = new Date().toISOString();
      const newCards: Flashcard[] =
        payload.cards && payload.cards.length > 0
          ? payload.cards.map((c, idx) => ({
              id: `fc-${deckId}-${idx + 1}`,
              deckId,
              front: c.front,
              back: c.back,
              easeFactor: 2.5,
              intervalDays: 0,
              repetitions: 0,
              nextReviewAt: nowIso,
            }))
          : generateExtractiveFlashcards(deckId, payload.subject, payload.sourceText);

      setState((prev) => ({
        ...prev,
        decks: [newDeck, ...prev.decks],
        flashcards: [...newCards, ...prev.flashcards],
      }));
      return newDeck;
    },
    []
  );

  const reviewFlashcard = useCallback((cardId: string, quality: number) => {
    setState((prev) => {
      const card = prev.flashcards.find((c) => c.id === cardId);
      const gamification = appendActivityAndXp(
        prev,
        10,
        card ? `Reviewed flashcard: ${card.front.slice(0, 48)}` : 'Reviewed flashcard',
        'flashcard'
      );
      return {
        ...prev,
        flashcards: prev.flashcards.map((c) => {
          if (c.id !== cardId) return c;
          const sm2 = updateSm2({
            currentEase: c.easeFactor,
            currentInterval: c.intervalDays,
            currentRepetitions: c.repetitions,
            quality,
          });
          return { ...c, ...sm2 };
        }),
        ...gamification,
      };
    });
  }, []);

  const createQuiz = useCallback(
    (payload: {
      title: string;
      subject: string;
      difficulty: 'easy' | 'medium' | 'hard';
      sourceText: string;
      questions?: Quiz['questions'];
    }): Quiz => {
      const quizId = `quiz-${Date.now()}`;
      const questions =
        payload.questions && payload.questions.length > 0
          ? payload.questions.map((q, i) => ({ ...q, id: q.id || `q-${quizId}-${i + 1}`, subject: payload.subject }))
          : generateExtractiveQuizQuestions(payload.subject, payload.sourceText, 5);
      const newQuiz: Quiz = {
        id: quizId,
        title: payload.title,
        subject: payload.subject,
        difficulty: payload.difficulty,
        questions,
        createdAt: new Date().toISOString(),
      };
      setState((prev) => ({
        ...prev,
        quizzes: [newQuiz, ...prev.quizzes],
      }));
      return newQuiz;
    },
    []
  );

  const submitQuizAttempt = useCallback(
    (quizId: string, answers: Record<string, number>): QuizAttempt => {
      const quiz = state.quizzes.find((q) => q.id === quizId);
      if (!quiz) {
        throw new Error('Quiz not found');
      }
      let correctCount = 0;
      for (const q of quiz.questions) {
        if (answers[q.id] === q.correctIndex) correctCount++;
      }
      const score = quiz.questions.length > 0 ? Math.round((correctCount / quiz.questions.length) * 100) : 0;
      const attempt: QuizAttempt = {
        id: `qa-${Date.now()}`,
        quizId,
        subject: quiz.subject,
        title: quiz.title,
        answers,
        score,
        correctCount,
        totalCount: quiz.questions.length,
        submittedAt: new Date().toISOString(),
      };
      setState((prev) => {
        const xpAmount = score >= 80 ? 60 : 40;
        const gamification = appendActivityAndXp(
          prev,
          xpAmount,
          `Quiz completed: ${quiz.title} (${score}%)`,
          'quiz'
        );
        return {
          ...prev,
          quizAttempts: [attempt, ...prev.quizAttempts],
          ...gamification,
        };
      });
      return attempt;
    },
    [state.quizzes]
  );

  const createMockExam = useCallback(
    (payload: {
      title: string;
      subjects: string[];
      questionsPerSubject: number;
      durationMinutes: number;
      difficulty: 'easy' | 'medium' | 'hard';
    }): MockExam => {
      const examId = `exam-${Date.now()}`;
      const sections = payload.subjects.map((subj) => {
        const docsText = state.documents
          .filter((d) => d.subject.toLowerCase() === subj.toLowerCase() && d.status === 'approved')
          .map((d) => `${d.description}\n${d.contentText}`)
          .join('\n');
        const questions = generateExtractiveQuizQuestions(subj, docsText, payload.questionsPerSubject).map(
          (q, idx) => ({
            ...q,
            id: `mq-${examId}-${subj}-${idx + 1}`,
            subject: subj,
          })
        );
        return { subject: subj, questions };
      });

      const exam: MockExam = {
        id: examId,
        title: payload.title,
        subjects: payload.subjects,
        difficulty: payload.difficulty,
        durationMinutes: payload.durationMinutes,
        sections,
        status: 'ready',
        createdAt: new Date().toISOString(),
      };
      setState((prev) => ({
        ...prev,
        mockExams: [exam, ...prev.mockExams],
      }));
      return exam;
    },
    [state.documents]
  );

  const startMockExam = useCallback((examId: string) => {
    setState((prev) => ({
      ...prev,
      mockExams: prev.mockExams.map((e) => (e.id === examId ? { ...e, status: 'in_progress' } : e)),
    }));
  }, []);

  const submitMockExam = useCallback(
    (examId: string, answers: Record<string, number>): MockExamAttempt => {
      const exam = state.mockExams.find((e) => e.id === examId);
      if (!exam) throw new Error('Mock exam not found');

      let totalCorrect = 0;
      let totalQuestions = 0;
      const sectionScores: MockExamAttempt['sectionScores'] = {};

      for (const sec of exam.sections) {
        let secCorrect = 0;
        for (const q of sec.questions) {
          totalQuestions++;
          if (answers[q.id] === q.correctIndex) {
            secCorrect++;
            totalCorrect++;
          }
        }
        const total = sec.questions.length;
        sectionScores[sec.subject] = {
          correct: secCorrect,
          total,
          score: total > 0 ? Math.round((secCorrect / total) * 100) : 0,
        };
      }

      const overallScore = totalQuestions > 0 ? Math.round((totalCorrect / totalQuestions) * 100) : 0;
      const attempt: MockExamAttempt = {
        id: `ma-${Date.now()}`,
        examId,
        title: exam.title,
        answers,
        overallScore,
        sectionScores,
        submittedAt: new Date().toISOString(),
      };

      setState((prev) => {
        const gamification = appendActivityAndXp(
          prev,
          100,
          `Mock exam graded: ${exam.title} (${overallScore}%)`,
          'mock_exam'
        );
        return {
          ...prev,
          mockExams: prev.mockExams.map((e) => (e.id === examId ? { ...e, status: 'graded' } : e)),
          mockExamAttempts: [attempt, ...prev.mockExamAttempts],
          ...gamification,
        };
      });
      return attempt;
    },
    [state.mockExams]
  );

  const setActiveConversationId = useCallback((id: string) => {
    setState((prev) => ({ ...prev, activeConversationId: id }));
  }, []);

  const createConversation = useCallback((): string => {
    const id = `conv-${Date.now()}`;
    const conv: Conversation = {
      id,
      title: 'New AI Tutor Session',
      stylePreferences: {},
      messages: [],
      updatedAt: new Date().toISOString(),
    };
    setState((prev) => ({
      ...prev,
      conversations: [conv, ...prev.conversations],
      activeConversationId: id,
    }));
    return id;
  }, []);

  const updateConversation = useCallback((conv: Conversation) => {
    setState((prev) => ({
      ...prev,
      conversations: prev.conversations.map((c) => (c.id === conv.id ? conv : c)),
    }));
  }, []);

  const markNotificationRead = useCallback((id: string) => {
    setState((prev) => ({
      ...prev,
      notifications: prev.notifications.map((n) => (n.id === id ? { ...n, read: true } : n)),
    }));
  }, []);

  const markAllNotificationsRead = useCallback(() => {
    setState((prev) => ({
      ...prev,
      notifications: prev.notifications.map((n) => ({ ...n, read: true })),
    }));
  }, []);

  const updateNotificationPrefs = useCallback((notificationPrefs: NotificationPreferences) => {
    setState((prev) => ({ ...prev, notificationPrefs }));
  }, []);

  const subscribeToPlan = useCallback((planCode: string) => {
    setState((prev) => ({
      ...prev,
      activeSubscriptionCode: planCode,
    }));
  }, []);

  const cancelSubscription = useCallback(() => {
    setState((prev) => ({
      ...prev,
      activeSubscriptionCode: null,
    }));
  }, []);

  const claimDailyCheckIn = useCallback((): boolean => {
    const todayKey = formatLocalDateKey();
    if (state.activityDates.includes(todayKey)) {
      return false;
    }
    setState((prev) => {
      if (prev.activityDates.includes(todayKey)) return prev;
      const gamification = appendActivityAndXp(
        prev,
        25,
        'Daily study check-in',
        'check_in'
      );
      return {
        ...prev,
        ...gamification,
      };
    });
    return true;
  }, [state.activityDates]);

  const xpLevel = useMemo(() => {
    const totalXp = state.xpEvents.reduce((sum, evt) => sum + evt.amount, 0);
    return computeXpLevelInfo(totalXp);
  }, [state.xpEvents]);

  const studyStreak = useMemo(
    () => computeStudyStreak(state.activityDates),
    [state.activityDates]
  );

  const value = useMemo<MindoraContextValue>(
    () => ({
      ...state,
      activeTab,
      subView,
      pendingAiPrompt,
      setActiveTab,
      setSubView,
      navigate,
      setTheme,
      setLanguage,
      toggleRole,
      signOut,
      signInDemo,
      registerOrSignIn,
      completeOnboarding,
      resetDemoWorkspace,
      createStudyPlan,
      reschedulePlan,
      completeSession,
      skipSession,
      handoffToAiTutor,
      clearPendingAiPrompt,
      submitDocument,
      moderateDocument,
      toggleBookmarkPaper,
      downloadPastPaper,
      createFlashcardDeck,
      reviewFlashcard,
      createQuiz,
      submitQuizAttempt,
      createMockExam,
      startMockExam,
      submitMockExam,
      setActiveConversationId,
      createConversation,
      updateConversation,
      markNotificationRead,
      markAllNotificationsRead,
      updateNotificationPrefs,
      subscribeToPlan,
      cancelSubscription,
      xpLevel,
      studyStreak,
      claimDailyCheckIn,
    }),
    [
      state,
      activeTab,
      subView,
      pendingAiPrompt,
      setActiveTab,
      navigate,
      setTheme,
      setLanguage,
      toggleRole,
      signOut,
      signInDemo,
      registerOrSignIn,
      completeOnboarding,
      resetDemoWorkspace,
      createStudyPlan,
      reschedulePlan,
      completeSession,
      skipSession,
      handoffToAiTutor,
      clearPendingAiPrompt,
      submitDocument,
      moderateDocument,
      toggleBookmarkPaper,
      downloadPastPaper,
      createFlashcardDeck,
      reviewFlashcard,
      createQuiz,
      submitQuizAttempt,
      createMockExam,
      startMockExam,
      submitMockExam,
      setActiveConversationId,
      createConversation,
      updateConversation,
      markNotificationRead,
      markAllNotificationsRead,
      updateNotificationPrefs,
      subscribeToPlan,
      cancelSubscription,
      xpLevel,
      studyStreak,
      claimDailyCheckIn,
    ]
  );

  return <MindoraContext.Provider value={value}>{children}</MindoraContext.Provider>;
};

export function useMindora(): MindoraContextValue {
  const ctx = useContext(MindoraContext);
  if (!ctx) throw new Error('useMindora must be used inside MindoraProvider');
  return ctx;
}
