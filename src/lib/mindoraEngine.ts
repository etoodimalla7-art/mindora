import type {
  ChatStylePreferences,
  DocumentAnalysis,
  DocumentItem,
  Flashcard,
  LanguageCode,
  MockExamAttempt,
  QuizAttempt,
  QuizQuestion,
  ReadinessDimensions,
  StreakDayCell,
  StudyPlan,
  StudySessionItem,
  StudyStreakInfo,
  WeakTopic,
  XpEvent,
  XpLevelInfo,
} from '../types/mindora';

// ============================================================
// Phase 4 & 5: Document Validation & Analysis Pipeline
// ============================================================

export const MIN_DESCRIPTION_WORDS = 500;
export const MAX_REPEATED_WORD_RATIO = 0.35;

export function countWords(text: string): number {
  const matches = text.match(/\b\w+\b/g);
  return matches ? matches.length : 0;
}

export function hasExcessiveRepetition(text: string): boolean {
  const words = (text.toLowerCase().match(/\b\w+\b/g) ?? []);
  if (words.length < 20) return false;
  const counts = new Map<string, number>();
  let maxCount = 0;
  for (const w of words) {
    const next = (counts.get(w) ?? 0) + 1;
    counts.set(w, next);
    if (next > maxCount) maxCount = next;
  }
  return maxCount / words.length > MAX_REPEATED_WORD_RATIO;
}

export function validateDocumentDescription(text: string): string[] {
  const problems: string[] = [];
  const wc = countWords(text);
  if (wc < MIN_DESCRIPTION_WORDS) {
    problems.push(`Description must be at least ${MIN_DESCRIPTION_WORDS} words (currently ${wc}).`);
  }
  if (hasExcessiveRepetition(text)) {
    problems.push('Description looks like repeated filler text rather than a real academic summary.');
  }
  return problems;
}

const FRENCH_MARKERS = ['le', 'la', 'les', 'des', 'une', 'est', 'dans', 'pour', 'avec', 'par', 'qui', 'sur'];
const ENGLISH_MARKERS = ['the', 'and', 'is', 'are', 'for', 'with', 'that', 'this', 'from', 'which', 'of', 'to'];

export function detectTextLanguage(text: string): LanguageCode {
  const tokens = text.toLowerCase().match(/\b[a-zàâçéèêëîïôûùüÿñæœ]+\b/g) ?? [];
  let frHits = 0;
  let enHits = 0;
  for (const tok of tokens) {
    if (FRENCH_MARKERS.includes(tok)) frHits++;
    if (ENGLISH_MARKERS.includes(tok)) enHits++;
  }
  return frHits > enHits ? 'fr' : 'en';
}

const SUBJECT_KEYWORDS: Record<string, string[]> = {
  Mathematics: ['derivative', 'integral', 'equation', 'matrix', 'vector', 'algebra', 'calculus', 'theorem', 'polynomial', 'probability'],
  Mathématiques: ['dérivée', 'intégrale', 'équation', 'suite', 'fonction', 'probabilité', 'vecteur', 'théorème'],
  Physics: ['velocity', 'acceleration', 'force', 'newton', 'thermodynamics', 'wave', 'electric', 'magnetic', 'quantum', 'energy'],
  Biology: ['cell', 'dna', 'mitosis', 'photosynthesis', 'enzyme', 'organism', 'genetics', 'respiration', 'membrane'],
  Chemistry: ['molecule', 'atom', 'reaction', 'acid', 'base', 'molar', 'equilibrium', 'covalent', 'oxidation'],
  'Computer Science': ['algorithm', 'complexity', 'binary', 'recursion', 'database', 'compiler', 'graph', 'tree', 'protocol'],
};

export function classifyDocumentSubject(text: string, fallbackSubject: string): string {
  const lower = text.toLowerCase();
  let bestSubject = fallbackSubject;
  let bestHits = 0;
  for (const [subject, keywords] of Object.entries(SUBJECT_KEYWORDS)) {
    let hits = 0;
    for (const kw of keywords) {
      if (lower.includes(kw)) hits++;
    }
    if (hits > bestHits) {
      bestHits = hits;
      bestSubject = subject;
    }
  }
  return bestSubject;
}

function jaccardSimilarity(a: string, b: string): number {
  const setA = new Set(a.toLowerCase().match(/\b\w{4,}\b/g) ?? []);
  const setB = new Set(b.toLowerCase().match(/\b\w{4,}\b/g) ?? []);
  if (setA.size === 0 || setB.size === 0) return 0;
  let intersection = 0;
  for (const item of setA) {
    if (setB.has(item)) intersection++;
  }
  const union = setA.size + setB.size - intersection;
  return union === 0 ? 0 : intersection / union;
}

export function analyzeDocumentSubmission(
  candidate: {
    title: string;
    subject: string;
    language: LanguageCode;
    description: string;
    contentText: string;
  },
  existingDocs: DocumentItem[]
): DocumentAnalysis {
  const combined = `${candidate.description}\n${candidate.contentText}`.trim();
  const problems = validateDocumentDescription(candidate.description);
  const warnings: string[] = [];

  const detectedLanguage = detectTextLanguage(combined);
  const languageMismatch = combined.length > 60 && detectedLanguage !== candidate.language;
  if (languageMismatch) {
    problems.push(
      `Declared language (${candidate.language.toUpperCase()}) does not match detected content language (${detectedLanguage.toUpperCase()}).`
    );
  }

  const suggestedSubject = classifyDocumentSubject(combined, candidate.subject);
  const subjectMismatch =
    suggestedSubject.toLowerCase() !== candidate.subject.toLowerCase() &&
    !candidate.subject.toLowerCase().includes(suggestedSubject.toLowerCase());
  if (subjectMismatch) {
    warnings.push(`Content keywords suggest "${suggestedSubject}" rather than "${candidate.subject}".`);
  }

  let duplicateSimilarity = 0;
  let possibleDuplicateOf: string | undefined;
  for (const doc of existingDocs) {
    const sim = jaccardSimilarity(combined, `${doc.description}\n${doc.contentText}`);
    if (sim > duplicateSimilarity) {
      duplicateSimilarity = sim;
      possibleDuplicateOf = doc.title;
    }
  }
  if (duplicateSimilarity >= 0.85 && possibleDuplicateOf) {
    warnings.push(
      `High similarity (${Math.round(duplicateSimilarity * 100)}%) detected with existing document "${possibleDuplicateOf}".`
    );
  }

  return {
    detectedLanguage,
    languageMismatch,
    suggestedSubject,
    subjectMismatch,
    duplicateSimilarity: Number(duplicateSimilarity.toFixed(2)),
    possibleDuplicateOf,
    wordCount: countWords(candidate.description),
    problems,
    warnings,
  };
}

// ============================================================
// Phase 7: Study Planner Generator
// ============================================================

export function buildSessionPlan(params: {
  planId: string;
  subjects: string[];
  topicsBySubject: Record<string, string[]>;
  startDate: string;
  targetDate: string;
  dailyMinutes: number;
}): StudySessionItem[] {
  const subjects = params.subjects.length > 0 ? params.subjects : ['General Study'];
  const start = new Date(`${params.startDate}T00:00:00`);
  const end = new Date(`${params.targetDate}T00:00:00`);
  const rawDays = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1;
  const totalDays = Math.min(Math.max(rawDays, 3), 21); // generate up to 21 upcoming days for snappy UI

  const topicPointers: Record<string, number> = {};
  const sessions: StudySessionItem[] = [];

  for (let day = 0; day < totalDays; day++) {
    const subject = subjects[day % subjects.length];
    const topics = params.topicsBySubject[subject] ?? ['Core concepts review', 'Worked examples', 'Past paper practice'];
    const idx = topicPointers[subject] ?? 0;
    const topic = topics[idx % topics.length];
    topicPointers[subject] = idx + 1;

    const d = new Date(start);
    d.setDate(start.getDate() + day);
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');

    sessions.push({
      id: `sess-${params.planId}-${day + 1}`,
      planId: params.planId,
      subject,
      topic,
      title: `${subject}: ${topic}`,
      objective: `Master key definitions, derivations, and exam-style problems for ${topic}.`,
      scheduledDate: `${yyyy}-${mm}-${dd}`,
      durationMinutes: params.dailyMinutes,
      status: 'pending',
    });
  }

  return sessions;
}

export function reschedulePendingSessions(sessions: StudySessionItem[], planId: string, fromDate: string): StudySessionItem[] {
  const pending = sessions.filter((s) => s.planId === planId && s.status === 'pending');
  const start = new Date(`${fromDate}T00:00:00`);
  let offset = 0;

  return sessions.map((s) => {
    if (s.planId !== planId || s.status !== 'pending') return s;
    const d = new Date(start);
    d.setDate(start.getDate() + offset);
    offset++;
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return { ...s, scheduledDate: `${yyyy}-${mm}-${dd}` };
  });
}

// ============================================================
// Phase 8 & 9: AI Intent, Stopword-Filtered RAG, Calculator & Tutor Style
// ============================================================

const STOPWORDS = new Set([
  'the', 'is', 'are', 'was', 'were', 'of', 'in', 'to', 'for', 'and', 'or', 'a', 'an', 'what', 'how', 'why',
  'when', 'where', 'who', 'which', 'this', 'that', 'with', 'from', 'about', 'can', 'you', 'explain', 'please',
  'my', 'me', 'tell', 'give', 'le', 'la', 'les', 'de', 'des', 'du', 'un', 'une', 'et', 'ou', 'est', 'dans',
  'pour', 'avec', 'sur', 'que', 'qui', 'quoi', 'comment', 'expliquer', 'mon', 'ma', 'mes',
]);

export function classifyMessageIntent(message: string): 'greeting' | 'calculator' | 'question' {
  const trimmed = message.trim().toLowerCase();
  if (/^(hi|hello|hey|bonjour|salut|good morning|good afternoon|good evening)[!. ]*$/.test(trimmed)) {
    return 'greeting';
  }
  // Safe arithmetic check e.g. "sqrt(144) + 8*3" or "(12 + 4) / 2"
  if (/^[0-9+\-*/().\s^sqrtpie]+$/.test(trimmed) && /[0-9]/.test(trimmed) && /[+\-*/^]|sqrt/.test(trimmed)) {
    return 'calculator';
  }
  return 'question';
}

export function evaluateSafeMath(expr: string): string | null {
  try {
    const cleaned = expr
      .trim()
      .toLowerCase()
      .replace(/\^/g, '**')
      .replace(/sqrt\(/g, 'Math.sqrt(')
      .replace(/\bpi\b/g, 'Math.PI')
      .replace(/\be\b/g, 'Math.E');
    if (!/^[0-9+\-*/().\sMathsqrtPIE]+$/.test(cleaned)) return null;
    const val = Function(`"use strict"; return (${cleaned});`)();
    if (typeof val === 'number' && Number.isFinite(val)) {
      return Number.isInteger(val) ? String(val) : String(Number(val.toFixed(6)));
    }
    return null;
  } catch {
    return null;
  }
}

export function retrieveCourseContext(
  query: string,
  documents: DocumentItem[]
): { contextText: string; citedDocuments: string[] } {
  const queryTerms = Array.from(
    new Set(
      (query.toLowerCase().match(/\b[a-z0-9àâçéèêëîïôûùüÿñæœ]{3,}\b/g) ?? []).filter((w) => !STOPWORDS.has(w))
    )
  );
  if (queryTerms.length === 0) return { contextText: '', citedDocuments: [] };

  const scored: Array<{ doc: DocumentItem; excerpt: string; score: number }> = [];

  for (const doc of documents) {
    const fullText = `${doc.title}\n${doc.subject}\n${doc.description}\n${doc.contentText}`;
    const sentences = fullText.split(/(?<=[.!?])\s+|\n+/).filter((s) => s.trim().length > 15);

    let bestScore = 0;
    const matchedSentences: string[] = [];

    for (const sentence of sentences) {
      const lower = sentence.toLowerCase();
      let hits = 0;
      for (const term of queryTerms) {
        if (lower.includes(term)) hits++;
      }
      if (hits > 0) {
        bestScore += hits;
        matchedSentences.push(sentence.trim());
      }
    }

    if (bestScore >= 1 && matchedSentences.length > 0) {
      scored.push({
        doc,
        excerpt: matchedSentences.slice(0, 4).join(' '),
        score: bestScore,
      });
    }
  }

  scored.sort((a, b) => b.score - a.score);
  const top = scored.slice(0, 2);
  if (top.length === 0) return { contextText: '', citedDocuments: [] };

  return {
    contextText: top.map((item) => `[Document: ${item.doc.title} (${item.doc.subject})]\n${item.excerpt}`).join('\n\n'),
    citedDocuments: top.map((item) => item.doc.title),
  };
}

export function detectStyleUpdates(text: string): Partial<ChatStylePreferences> {
  const lowered = text.toLowerCase();
  const updates: Partial<ChatStylePreferences> = {};

  if (['explain it more simply', 'simpler', "i don't understand", 'easier', 'plus simplement'].some((p) => lowered.includes(p))) {
    updates.depth = 'simpler';
  } else if (['university level', 'advanced level', 'niveau universitaire'].some((p) => lowered.includes(p))) {
    updates.depth = 'university';
  } else if (['more detail', 'in depth', 'go deeper', 'plus de détails'].some((p) => lowered.includes(p))) {
    updates.depth = 'detailed';
  }

  if (['give me an example', 'another example', 'exemple'].some((p) => lowered.includes(p))) {
    updates.wantExample = true;
  }
  if (['show me the steps', 'step by step', 'étape par étape'].some((p) => lowered.includes(p))) {
    updates.wantSteps = true;
  }
  if (['give me an exercise', 'practice question', 'quiz me', 'exercice'].some((p) => lowered.includes(p))) {
    updates.wantExercise = true;
  }
  if (["don't give me the answer", 'guide me', 'socratic', 'mode socratique'].some((p) => lowered.includes(p))) {
    updates.socratic = true;
  } else if (['just tell me the answer', 'give me the answer', 'stop asking questions'].some((p) => lowered.includes(p))) {
    updates.socratic = false;
  }

  return updates;
}

export function buildStyleInstructionText(prefs: ChatStylePreferences): string {
  const parts: string[] = [];
  if (prefs.depth === 'simpler') parts.push('Explain in the simplest terms possible, avoiding unnecessary jargon.');
  if (prefs.depth === 'detailed') parts.push('Provide a thorough, detailed explanation.');
  if (prefs.depth === 'university') parts.push('Explain at an undergraduate/university level of rigor.');
  if (prefs.wantExample) parts.push('Include a concrete worked example.');
  if (prefs.wantSteps) parts.push('Break the explanation down into clear numbered steps.');
  if (prefs.wantExercise) parts.push('End with a practice exercise for the student to attempt.');
  if (prefs.socratic) {
    parts.push(
      'Use the Socratic method: do NOT reveal the final answer directly. Ask guiding questions that help the student discover the answer one step at a time.'
    );
  }
  return parts.join(' ');
}

// ============================================================
// Phase 10: SM-2 Spaced Repetition & Extractive Flashcards/Quiz
// ============================================================

export function updateSm2(params: {
  currentEase: number;
  currentInterval: number;
  currentRepetitions: number;
  quality: number; // 0..5 (1=Hard, 3=Good, 5=Easy)
  now?: Date;
}): {
  easeFactor: number;
  intervalDays: number;
  repetitions: number;
  nextReviewAt: string;
  lastState: 'known' | 'uncertain' | 'forgotten';
} {
  const { currentEase, currentInterval, currentRepetitions, quality } = params;
  const now = params.now ?? new Date();

  let newEase = currentEase + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  newEase = Math.max(1.3, Number(newEase.toFixed(2)));

  let newReps: number;
  let newInterval: number;
  if (quality < 3) {
    newReps = 0;
    newInterval = 1;
  } else {
    newReps = currentRepetitions + 1;
    if (newReps === 1) newInterval = 1;
    else if (newReps === 2) newInterval = 6;
    else newInterval = Math.round(currentInterval * newEase);
  }

  const next = new Date(now.getTime() + newInterval * 24 * 60 * 60 * 1000);
  const lastState: 'known' | 'uncertain' | 'forgotten' =
    quality >= 4 ? 'known' : quality === 3 ? 'uncertain' : 'forgotten';

  return {
    easeFactor: newEase,
    intervalDays: newInterval,
    repetitions: newReps,
    nextReviewAt: next.toISOString(),
    lastState,
  };
}

const PRONOUN_PREFIXES = new Set(['this', 'that', 'these', 'those', 'it', 'they', 'he', 'she', 'we', 'there', 'here']);

export function extractDefinitionsFromText(text: string): Array<{ term: string; definition: string }> {
  const sentences = text
    .split(/(?<=[.!?])\s+|\n+/)
    .map((s) => s.trim())
    .filter((s) => s.length >= 20);

  const pairs: Array<{ term: string; definition: string }> = [];

  for (const s of sentences) {
    const match = s.match(/^([A-Za-zÀ-ÿ0-9\s-]{3,48}?)\s+(?:is|are|refers to|represents|est|désigne)\s+(.{12,})$/i);
    if (!match) continue;
    const term = match[1].trim();
    const firstWord = term.toLowerCase().split(/\s+/)[0];
    if (PRONOUN_PREFIXES.has(firstWord)) continue;
    const definition = match[2].replace(/[.]+$/, '').trim();
    pairs.push({ term, definition });
  }

  return pairs;
}

export function generateExtractiveFlashcards(
  deckId: string,
  subject: string,
  sourceText: string
): Flashcard[] {
  const extracted = extractDefinitionsFromText(sourceText);
  const nowIso = new Date().toISOString();

  const pairs =
    extracted.length >= 2
      ? extracted.slice(0, 8)
      : [
          { term: `Core principle of ${subject}`, definition: `Review fundamental definitions and formulas in ${subject}.` },
          { term: `Problem-solving method in ${subject}`, definition: `Identify givens, select governing law, and verify units.` },
          { term: `Common exam pitfall in ${subject}`, definition: `Check boundary conditions, signs, and domain restrictions.` },
        ];

  return pairs.map((p, idx) => ({
    id: `fc-${deckId}-${idx + 1}`,
    deckId,
    front: `What is ${p.term}?`,
    back: p.definition,
    easeFactor: 2.5,
    intervalDays: 0,
    repetitions: 0,
    nextReviewAt: nowIso,
  }));
}

function deterministicShuffle<T>(items: T[], seed: number): T[] {
  const arr = [...items];
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.abs((seed * 9301 + i * 49297) % (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

export function generateExtractiveQuizQuestions(
  subject: string,
  sourceText: string,
  count = 5
): QuizQuestion[] {
  const extracted = extractDefinitionsFromText(sourceText);
  if (extracted.length < 3) {
    return [
      {
        id: `q-${Date.now()}-1`,
        subject,
        prompt: `Which approach best improves accuracy on ${subject} examination questions?`,
        options: [
          'Identifying given quantities, units, and applicable theorems before computing',
          'Skipping intermediate derivations to save time',
          'Memorizing final numeric answers without checking conditions',
          'Ignoring sign conventions in formulas',
        ],
        correctIndex: 0,
        explanation: 'Listing givens, units, and governing assumptions prevents most procedural errors.',
      },
      {
        id: `q-${Date.now()}-2`,
        subject,
        prompt: `When reviewing ${subject} past papers, what is the strongest indicator of concept mastery?`,
        options: [
          'Re-reading highlighted notes passively',
          'Explaining each step and solving unseen variations without notes',
          'Focusing only on familiar topics',
          'Reading the mark scheme before attempting the question',
        ],
        correctIndex: 1,
        explanation: 'Active recall on unseen problem variations proves true transfer and retention.',
      },
      {
        id: `q-${Date.now()}-3`,
        subject,
        prompt: `How should you validate a final answer in ${subject}?`,
        options: [
          'Check dimensional consistency, magnitude, and limiting cases',
          'Assume the first calculation is always exact',
          'Round all intermediate constants to 1 significant figure',
          'Omit units from the final line',
        ],
        correctIndex: 0,
        explanation: 'Dimensional analysis and limiting-case checks catch algebraic slips immediately.',
      },
    ].slice(0, count);
  }

  const allDefs = extracted.map((e) => e.definition);
  return extracted.slice(0, count).map((item, idx) => {
    const distractors = allDefs.filter((d) => d !== item.definition).slice(0, 3);
    while (distractors.length < 3) {
      distractors.push(`A secondary property unrelated to ${item.term}`);
    }
    const rawOptions = [item.definition, ...distractors];
    const shuffled = deterministicShuffle(rawOptions, idx + item.term.length);
    const correctIndex = shuffled.indexOf(item.definition);

    return {
      id: `q-${Date.now()}-${idx + 1}`,
      subject,
      prompt: `Which statement accurately defines "${item.term}"?`,
      options: shuffled,
      correctIndex,
      explanation: `${item.term} is defined as: ${item.definition}.`,
    };
  });
}

// ============================================================
// Phase 12 & 14: Honest Readiness Analytics & Quiet Hours
// ============================================================

export function computeReadinessAnalytics(params: {
  quizAttempts: QuizAttempt[];
  mockExamAttempts: MockExamAttempt[];
  flashcards: Flashcard[];
  streakDays: number;
}): {
  dimensions: ReadinessDimensions;
  masteryBySubject: Record<string, number>;
  weakTopics: WeakTopic[];
} {
  const { quizAttempts, mockExamAttempts, flashcards, streakDays } = params;

  const quizBySubject = new Map<string, number[]>();
  for (const a of quizAttempts) {
    const list = quizBySubject.get(a.subject) ?? [];
    list.push(a.score);
    quizBySubject.set(a.subject, list);
  }

  const avgQuizScore =
    quizAttempts.length > 0
      ? quizAttempts.reduce((acc, a) => acc + a.score, 0) / quizAttempts.length
      : null;

  const reviewedCards = flashcards.filter((c) => c.lastState !== undefined);
  const knownCount = reviewedCards.filter((c) => c.lastState === 'known').length;
  const flashcardKnownRatio = reviewedCards.length > 0 ? knownCount / reviewedCards.length : null;

  const avgMockScore =
    mockExamAttempts.length > 0
      ? mockExamAttempts.reduce((acc, m) => acc + m.overallScore, 0) / mockExamAttempts.length
      : null;

  const masteryBySubject: Record<string, number> = {};
  for (const [subj, scores] of quizBySubject.entries()) {
    const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
    masteryBySubject[subj] = Number(avg.toFixed(1));
  }
  for (const m of mockExamAttempts) {
    for (const [subj, sec] of Object.entries(m.sectionScores)) {
      if (masteryBySubject[subj] !== undefined) {
        masteryBySubject[subj] = Number(((masteryBySubject[subj] + sec.score) / 2).toFixed(1));
      } else {
        masteryBySubject[subj] = sec.score;
      }
    }
  }

  const subjects = Object.keys(masteryBySubject);
  const weakSubjectRatio =
    subjects.length === 0
      ? 1.0
      : subjects.filter((s) => masteryBySubject[s] < 50).length / subjects.length;

  const knowledge = avgQuizScore ?? 0;
  const practice = Math.min(100, quizAttempts.length * 10 + reviewedCards.length * 2);
  const retention = flashcardKnownRatio !== null ? flashcardKnownRatio * 100 : 0;
  const pastPapers = avgMockScore ?? 0;
  const weakTopicsScore = (1 - weakSubjectRatio) * 100;
  const consistency = Math.min(100, streakDays * (100 / 14));

  const dimensions: ReadinessDimensions = {
    knowledge: Math.round(knowledge),
    practice: Math.round(practice),
    retention: Math.round(retention),
    pastPapers: Math.round(pastPapers),
    weakTopics: Math.round(weakTopicsScore),
    consistency: Math.round(consistency),
    overall: Math.round((knowledge + practice + retention + pastPapers + weakTopicsScore + consistency) / 6),
  };

  const weakTopics: WeakTopic[] = Object.entries(masteryBySubject)
    .filter(([, score]) => score < 70)
    .sort((a, b) => a[1] - b[1])
    .slice(0, 4)
    .map(([subject, score]) => ({
      subject,
      topic: `${subject} core problem sets`,
      mastery: Number((score / 100).toFixed(2)),
    }));

  return { dimensions, masteryBySubject, weakTopics };
}

export function isQuietHours(hour: number, startHour: number, endHour: number): boolean {
  if (startHour === endHour) return false;
  if (startHour < endHour) {
    return hour >= startHour && hour < endHour;
  }
  return hour >= startHour || hour < endHour;
}

// ============================================================
// Phase 15 & 16: Contribution Bonus Math (+5 credits per 5 approvals)
// ============================================================

export function creditsFromNewApprovals(previousApprovedCount: number, newApprovedCount: number): number {
  const prevMilestones = Math.floor(previousApprovedCount / 5);
  const nextMilestones = Math.floor(newApprovedCount / 5);
  return Math.max(0, nextMilestones - prevMilestones) * 5;
}

// ============================================================
// Phase 17: Study Streak & XP Level System
// ============================================================

export function formatLocalDateKey(date: Date = new Date()): string {
  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const dd = String(date.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

function addDaysToKey(dateKey: string, deltaDays: number): string {
  const [y, m, d] = dateKey.split('-').map(Number);
  const dt = new Date(y, (m || 1) - 1, d || 1);
  dt.setDate(dt.getDate() + deltaDays);
  return formatLocalDateKey(dt);
}

const LEVEL_THRESHOLDS: Array<{ floor: number; titleEn: string; titleFr: string }> = [
  { floor: 0, titleEn: 'Apprentice', titleFr: 'Apprenti' },
  { floor: 200, titleEn: 'Scholar', titleFr: 'Érudit' },
  { floor: 450, titleEn: 'Challenger', titleFr: 'Compétiteur' },
  { floor: 800, titleEn: 'Master', titleFr: 'Maître' },
  { floor: 1250, titleEn: 'Laureate', titleFr: 'Lauréat' },
  { floor: 1800, titleEn: 'Grand Scholar', titleFr: 'Grand Lauréat' },
];

export function computeXpLevelInfo(totalXpInput: number): XpLevelInfo {
  const totalXp = Math.max(0, Math.floor(totalXpInput));

  let level = 1;
  let currentLevelFloor = 0;
  let nextLevelFloor = 200;
  let titleEn = LEVEL_THRESHOLDS[0].titleEn;
  let titleFr = LEVEL_THRESHOLDS[0].titleFr;

  for (let i = 0; i < LEVEL_THRESHOLDS.length; i++) {
    if (totalXp >= LEVEL_THRESHOLDS[i].floor) {
      level = i + 1;
      currentLevelFloor = LEVEL_THRESHOLDS[i].floor;
      titleEn = LEVEL_THRESHOLDS[i].titleEn;
      titleFr = LEVEL_THRESHOLDS[i].titleFr;
      nextLevelFloor =
        i + 1 < LEVEL_THRESHOLDS.length ? LEVEL_THRESHOLDS[i + 1].floor : currentLevelFloor + 600;
    }
  }

  // Handle levels beyond the predefined table (+600 XP per level)
  while (totalXp >= nextLevelFloor) {
    level++;
    currentLevelFloor = nextLevelFloor;
    nextLevelFloor = currentLevelFloor + 600;
    titleEn = 'Grand Scholar';
    titleFr = 'Grand Lauréat';
  }

  const xpIntoLevel = totalXp - currentLevelFloor;
  const xpForNextLevel = Math.max(1, nextLevelFloor - currentLevelFloor);
  const xpRemaining = Math.max(0, nextLevelFloor - totalXp);
  const progressPercent = Math.min(100, Math.max(0, Math.round((xpIntoLevel / xpForNextLevel) * 100)));

  return {
    level,
    titleEn,
    titleFr,
    totalXp,
    currentLevelFloor,
    nextLevelFloor,
    xpIntoLevel,
    xpForNextLevel,
    xpRemaining,
    progressPercent,
  };
}

const WEEKDAY_EN = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const WEEKDAY_FR = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

export function computeStudyStreak(
  activityDatesInput: string[],
  now: Date = new Date()
): StudyStreakInfo {
  const uniqueDates = Array.from(
    new Set(activityDatesInput.filter((d) => /^\d{4}-\d{2}-\d{2}$/.test(d)))
  ).sort();
  const dateSet = new Set(uniqueDates);

  const todayKey = formatLocalDateKey(now);
  const yesterdayKey = addDaysToKey(todayKey, -1);
  const activeToday = dateSet.has(todayKey);

  // Current consecutive streak ending today or yesterday
  let currentStreak = 0;
  let cursor: string | null = activeToday ? todayKey : dateSet.has(yesterdayKey) ? yesterdayKey : null;
  while (cursor && dateSet.has(cursor)) {
    currentStreak++;
    cursor = addDaysToKey(cursor, -1);
  }

  // Longest consecutive streak across all recorded activity dates
  let longestStreak = 0;
  let running = 0;
  let prevDate: string | null = null;
  for (const d of uniqueDates) {
    if (prevDate && addDaysToKey(prevDate, 1) === d) {
      running++;
    } else {
      running = 1;
    }
    if (running > longestStreak) longestStreak = running;
    prevDate = d;
  }

  const atRisk = !activeToday && currentStreak > 0;

  const last7Days: StreakDayCell[] = [];
  for (let offset = -6; offset <= 0; offset++) {
    const dt = new Date(now.getFullYear(), now.getMonth(), now.getDate() + offset);
    const key = formatLocalDateKey(dt);
    const wd = dt.getDay();
    last7Days.push({
      date: key,
      labelEn: WEEKDAY_EN[wd],
      labelFr: WEEKDAY_FR[wd],
      active: dateSet.has(key),
      isToday: offset === 0,
    });
  }

  return {
    currentStreak,
    longestStreak,
    activeToday,
    atRisk,
    totalActiveDays: uniqueDates.length,
    last7Days,
  };
}

export function deriveGamificationFromHistory(params: {
  sessions: StudySessionItem[];
  quizAttempts: QuizAttempt[];
  mockExamAttempts: MockExamAttempt[];
  documents: DocumentItem[];
  flashcards: Flashcard[];
  userId?: string;
}): { xpEvents: XpEvent[]; activityDates: string[] } {
  const xpEvents: XpEvent[] = [];
  const dates = new Set<string>();

  for (const s of params.sessions) {
    if (s.status === 'completed') {
      const ts = s.completedAt || `${s.scheduledDate}T12:00:00.000Z`;
      dates.add(ts.slice(0, 10));
      xpEvents.push({
        id: `xp-sess-${s.id}`,
        amount: 50,
        reason: `Completed session: ${s.title}`,
        category: 'session',
        createdAt: ts,
      });
    }
  }

  for (const qa of params.quizAttempts) {
    const ts = qa.submittedAt;
    dates.add(ts.slice(0, 10));
    const amount = qa.score >= 80 ? 60 : 40;
    xpEvents.push({
      id: `xp-qa-${qa.id}`,
      amount,
      reason: `Quiz completed: ${qa.title} (${qa.score}%)`,
      category: 'quiz',
      createdAt: ts,
    });
  }

  for (const ma of params.mockExamAttempts) {
    const ts = ma.submittedAt;
    dates.add(ts.slice(0, 10));
    xpEvents.push({
      id: `xp-ma-${ma.id}`,
      amount: 100,
      reason: `Mock exam graded: ${ma.title} (${ma.overallScore}%)`,
      category: 'mock_exam',
      createdAt: ts,
    });
  }

  for (const doc of params.documents) {
    if (!params.userId || doc.uploaderId === params.userId) {
      dates.add(doc.createdAt.slice(0, 10));
      xpEvents.push({
        id: `xp-doc-${doc.id}`,
        amount: 30,
        reason: `Contributed document: ${doc.title}`,
        category: 'document',
        createdAt: doc.createdAt,
      });
    }
  }

  const reviewedCount = params.flashcards.filter((c) => c.lastState !== undefined).length;
  if (reviewedCount > 0) {
    xpEvents.push({
      id: 'xp-fc-initial',
      amount: reviewedCount * 10,
      reason: `Reviewed ${reviewedCount} spaced-repetition flashcards`,
      category: 'flashcard',
      createdAt: new Date(Date.now() - 86400000).toISOString(),
    });
  }

  xpEvents.sort((a, b) => b.createdAt.localeCompare(a.createdAt));

  return {
    xpEvents,
    activityDates: Array.from(dates).sort(),
  };
}

