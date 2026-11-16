export type LanguageCode = 'en' | 'fr';
export type ThemeMode = 'light' | 'dark';
export type UserRole = 'student' | 'admin';

export interface EducationProfile {
  country: string;
  educationSystem: string;
  level: string;
  program: string;
  subjects: string[];
  goal: string;
  targetExamName: string;
  targetExamDate: string; // YYYY-MM-DD
  preferredStudyTimes: string[];
  notificationsEnabled: boolean;
  aiStyle: 'concise' | 'step_by_step' | 'socratic' | 'example_rich';
}

export interface UserProfile {
  id: string;
  fullName: string;
  email: string;
  role: UserRole;
  isVerified: boolean;
  preferredLanguage: LanguageCode;
  countryCode: string;
  onboardingCompleted: boolean;
  educationProfile: EducationProfile;
}

export type DocumentStatus =
  | 'draft'
  | 'under_review'
  | 'needs_revision'
  | 'approved'
  | 'rejected';

export interface DocumentAnalysis {
  detectedLanguage: LanguageCode;
  languageMismatch: boolean;
  suggestedSubject: string;
  subjectMismatch: boolean;
  duplicateSimilarity: number; // 0..1
  possibleDuplicateOf?: string;
  wordCount: number;
  problems: string[];
  warnings: string[];
}

export interface DocumentItem {
  id: string;
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
  status: DocumentStatus;
  rejectionReason?: string;
  uploaderId: string;
  uploaderName: string;
  createdAt: string;
  analysis?: DocumentAnalysis;
}

export interface PastPaper {
  id: string;
  title: string;
  country: string;
  system: string;
  level: string;
  subject: string;
  year: number;
  session?: string;
  summary: string;
  bookmarked: boolean;
  downloaded: boolean;
  documentId?: string;
}

export interface StudySessionItem {
  id: string;
  planId: string;
  subject: string;
  topic: string;
  title: string;
  objective: string;
  scheduledDate: string; // YYYY-MM-DD
  durationMinutes: number;
  status: 'pending' | 'in_progress' | 'completed' | 'skipped';
  completedAt?: string;
}

export interface StudyPlan {
  id: string;
  title: string;
  planType: 'exam' | 'subject';
  targetExamName?: string;
  targetDate?: string; // YYYY-MM-DD
  subjects: string[];
  dailyMinutes: number;
  createdAt: string;
}

export interface Flashcard {
  id: string;
  deckId: string;
  front: string;
  back: string;
  easeFactor: number;
  intervalDays: number;
  repetitions: number;
  nextReviewAt: string; // ISO
  lastState?: 'known' | 'uncertain' | 'forgotten';
}

export interface FlashcardDeck {
  id: string;
  title: string;
  subject: string;
  sourceDocumentId?: string;
  createdAt: string;
}

export interface QuizQuestion {
  id: string;
  subject: string;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
}

export interface Quiz {
  id: string;
  title: string;
  subject: string;
  difficulty: 'easy' | 'medium' | 'hard';
  questions: QuizQuestion[];
  createdAt: string;
}

export interface QuizAttempt {
  id: string;
  quizId: string;
  subject: string;
  title: string;
  answers: Record<string, number>;
  score: number; // 0..100
  correctCount: number;
  totalCount: number;
  submittedAt: string;
}

export interface MockExamSection {
  subject: string;
  questions: QuizQuestion[];
}

export interface MockExam {
  id: string;
  title: string;
  subjects: string[];
  difficulty: 'easy' | 'medium' | 'hard';
  durationMinutes: number;
  sections: MockExamSection[];
  status: 'ready' | 'in_progress' | 'graded';
  createdAt: string;
}

export interface MockExamAttempt {
  id: string;
  examId: string;
  title: string;
  answers: Record<string, number>;
  overallScore: number;
  sectionScores: Record<string, { correct: number; total: number; score: number }>;
  submittedAt: string;
}

export interface ChatStylePreferences {
  depth?: 'simpler' | 'detailed' | 'university';
  wantExample?: boolean;
  wantSteps?: boolean;
  wantExercise?: boolean;
  socratic?: boolean;
}

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  createdAt: string;
  source?: 'course_material' | 'general_knowledge' | 'calculator' | 'greeting';
  citedDocuments?: string[];
  imageDataUrl?: string;
  toolsUsed?: string[];
}

export interface Conversation {
  id: string;
  title: string;
  stylePreferences: ChatStylePreferences;
  messages: ChatMessage[];
  updatedAt: string;
}

export interface NotificationItem {
  id: string;
  type: 'session_upcoming' | 'session_missed' | 'exam_countdown' | 'moderation' | 'credits';
  title: string;
  body: string;
  read: boolean;
  createdAt: string;
  dedupKey?: string;
}

export interface NotificationPreferences {
  enabled: boolean;
  quietStartHour: number; // 0..23
  quietEndHour: number; // 0..23
}

export interface CreditTransaction {
  id: string;
  delta: number;
  reason: string;
  createdAt: string;
}

export interface SubscriptionPlan {
  code: string;
  name: string;
  description: string;
  tier: 'student' | 'premium';
  amountMinor: number;
  currency: string;
  billingCycle: 'monthly' | 'quarterly' | 'yearly';
  features: string[];
}

export interface ReadinessDimensions {
  knowledge: number;
  practice: number;
  retention: number;
  pastPapers: number;
  weakTopics: number;
  consistency: number;
  overall: number;
}

export interface WeakTopic {
  subject: string;
  topic: string;
  mastery: number; // 0..1
}

export type XpCategory = 'check_in' | 'session' | 'quiz' | 'mock_exam' | 'flashcard' | 'document';

export interface XpEvent {
  id: string;
  amount: number;
  reason: string;
  category: XpCategory;
  createdAt: string;
}

export interface XpLevelInfo {
  level: number;
  titleEn: string;
  titleFr: string;
  totalXp: number;
  currentLevelFloor: number;
  nextLevelFloor: number;
  xpIntoLevel: number;
  xpForNextLevel: number;
  xpRemaining: number;
  progressPercent: number;
}

export interface StreakDayCell {
  date: string; // YYYY-MM-DD
  labelEn: string;
  labelFr: string;
  active: boolean;
  isToday: boolean;
}

export interface StudyStreakInfo {
  currentStreak: number;
  longestStreak: number;
  activeToday: boolean;
  atRisk: boolean;
  totalActiveDays: number;
  last7Days: StreakDayCell[];
}

export type AppTab = 'home' | 'ai' | 'planner' | 'learn' | 'profile';

export type SubView =
  | { type: 'none' }
  | { type: 'readiness' }
  | { type: 'study_session'; sessionId: string }
  | { type: 'past_papers' }
  | { type: 'upload_document' }
  | { type: 'my_contributions' }
  | { type: 'flashcards'; deckId?: string }
  | { type: 'quizzes'; quizId?: string; attemptId?: string }
  | { type: 'mock_exams'; examId?: string; mode?: 'create' | 'take' | 'results' }
  | { type: 'notifications' }
  | { type: 'subscription' }
  | { type: 'admin_moderation' };
