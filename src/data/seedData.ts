import type {
  DocumentItem,
  Flashcard,
  FlashcardDeck,
  PastPaper,
  Quiz,
  QuizAttempt,
  StudyPlan,
  StudySessionItem,
  SubscriptionPlan,
  UserProfile,
} from '../types/mindora';

export const CATALOG_TOPICS_BY_SUBJECT: Record<string, string[]> = {
  Mathematics: [
    'Algebra & Polynomials',
    'Trigonometry',
    'Differentiation',
    'Integration by Parts',
    'Differential Equations',
    'Vectors & Matrices',
    'Statistics & Probability',
  ],
  Physics: [
    'Kinematics & Mechanics',
    'Waves & Optics',
    'Electricity & Circuits',
    'Gravitational & Electric Fields',
    'Thermodynamics',
    'Quantum Physics',
  ],
  Chemistry: [
    'Atomic Structure & Bonding',
    'Chemical Equilibrium',
    'Acids, Bases & Buffers',
    'Organic Reaction Mechanisms',
    'Electrochemistry',
  ],
  Biology: [
    'Cell Biology & Membranes',
    'Enzymes & Metabolism',
    'Cellular Respiration',
    'Genetics & Inheritance',
    'Human Physiology',
  ],
  Mathématiques: [
    'Suites numériques',
    'Fonctions et dérivées',
    'Calcul intégral',
    'Probabilités conditionnelles',
    "Géométrie dans l'espace",
  ],
};

export const INITIAL_USER: UserProfile = {
  id: 'usr-demo-1',
  fullName: 'Jean Baptiste',
  email: 'jean@mindora.edu',
  role: 'student',
  isVerified: true,
  preferredLanguage: 'en',
  countryCode: 'CM',
  onboardingCompleted: true,
  educationProfile: {
    country: 'Cameroon',
    educationSystem: 'GCE',
    level: 'Advanced Level',
    program: 'Science (S4)',
    subjects: ['Mathematics', 'Physics', 'Chemistry'],
    goal: 'Score A grades across all science papers',
    targetExamName: 'GCE Advanced Level 2027',
    targetExamDate: '2027-06-05',
    preferredStudyTimes: ['Morning (07:00 - 09:00)', 'Evening (19:00 - 21:00)'],
    notificationsEnabled: true,
    aiStyle: 'step_by_step',
  },
};

const TODAY = new Date().toISOString().slice(0, 10);

export const INITIAL_PLANS: StudyPlan[] = [
  {
    id: 'plan-gce-1',
    title: 'GCE Advanced Level Science Roadmap',
    planType: 'exam',
    targetExamName: 'GCE Advanced Level 2027',
    targetDate: '2027-06-05',
    subjects: ['Mathematics', 'Physics', 'Chemistry'],
    dailyMinutes: 45,
    createdAt: new Date(Date.now() - 5 * 86400000).toISOString(),
  },
];

export const INITIAL_SESSIONS: StudySessionItem[] = [
  {
    id: 'sess-1',
    planId: 'plan-gce-1',
    subject: 'Mathematics',
    topic: 'Differential Equations',
    title: 'First-Order Differential Equations & Integrating Factors',
    objective: 'Solve separable and linear first-order differential equations with initial conditions.',
    scheduledDate: TODAY,
    durationMinutes: 45,
    status: 'pending',
  },
  {
    id: 'sess-2',
    planId: 'plan-gce-1',
    subject: 'Physics',
    topic: 'Waves & Optics',
    title: 'Wave Interference & Diffraction Gratings',
    objective: 'Derive path difference conditions for constructive and destructive interference.',
    scheduledDate: new Date(Date.now() + 86400000).toISOString().slice(0, 10),
    durationMinutes: 45,
    status: 'pending',
  },
  {
    id: 'sess-3',
    planId: 'plan-gce-1',
    subject: 'Chemistry',
    topic: 'Chemical Equilibrium',
    title: "Le Chatelier's Principle & Kp Calculations",
    objective: 'Compute partial pressure equilibrium constants and predict shifts.',
    scheduledDate: new Date(Date.now() - 86400000).toISOString().slice(0, 10),
    durationMinutes: 40,
    status: 'completed',
    completedAt: new Date(Date.now() - 86400000).toISOString(),
  },
  {
    id: 'sess-4',
    planId: 'plan-gce-1',
    subject: 'Mathematics',
    topic: 'Integration by Parts',
    title: 'Integration by Parts & Trigonometric Substitutions',
    objective: 'Practice definite integrals involving products of algebraic and exponential functions.',
    scheduledDate: new Date(Date.now() - 2 * 86400000).toISOString().slice(0, 10),
    durationMinutes: 45,
    status: 'completed',
    completedAt: new Date(Date.now() - 2 * 86400000).toISOString(),
  },
];

export const INITIAL_DOCUMENTS: DocumentItem[] = [
  {
    id: 'doc-math-1',
    title: 'Advanced Calculus: Differential Equations & Integration Notes',
    subject: 'Mathematics',
    educationSystem: 'GCE',
    level: 'Advanced Level',
    language: 'en',
    fileName: 'gce_alevel_differential_equations.pdf',
    isExamPaper: false,
    description:
      'Comprehensive lecture notes covering first-order separable differential equations, linear equations with integrating factors, and integration by parts with worked exam examples.',
    contentText:
      'A differential equation is an equation that relates a function with one or more of its derivatives. ' +
      'Separable differential equations are equations of the form dy/dx = g(x)h(y) where variables can be isolated on opposite sides before integrating. ' +
      'An integrating factor is a multiplier mu(x) = exp(integral P(x) dx) used to transform a linear first-order differential equation dy/dx + P(x)y = Q(x) into an exact derivative. ' +
      'Integration by parts is a technique derived from the product rule stating that integral(u dv) = uv - integral(v du). ' +
      'An initial value problem is a differential equation paired with a specific condition y(x0) = y0 that uniquely determines the constant of integration.',
    status: 'approved',
    uploaderId: 'usr-demo-1',
    uploaderName: 'Jean Baptiste',
    createdAt: new Date(Date.now() - 6 * 86400000).toISOString(),
  },
  {
    id: 'doc-phys-1',
    title: 'Waves, Superposition & Mechanics Summary',
    subject: 'Physics',
    educationSystem: 'GCE',
    level: 'Advanced Level',
    language: 'en',
    fileName: 'alevel_physics_waves_mechanics.pdf',
    isExamPaper: false,
    description:
      'Summary of progressive waves, superposition, diffraction gratings, Newton laws of motion, and conservation of linear momentum for GCE Advanced Level candidates.',
    contentText:
      'Superposition is the principle that when two or more waves meet at a point, the resultant displacement equals the vector sum of the individual displacements. ' +
      'Coherent waves are wave sources that maintain a constant phase difference and identical frequency. ' +
      'Diffraction is the spreading of waves as they pass through an aperture or around an obstacle whose size is comparable to the wavelength. ' +
      'Momentum is the product of an object mass and its velocity, conserved in all isolated collisions. ' +
      'Simple harmonic motion is oscillatory motion in which the acceleration is directly proportional to displacement and directed toward the equilibrium position.',
    status: 'approved',
    uploaderId: 'usr-demo-1',
    uploaderName: 'Jean Baptiste',
    createdAt: new Date(Date.now() - 4 * 86400000).toISOString(),
  },
  {
    id: 'doc-pending-1',
    title: 'Organic Chemistry Reaction Mechanisms Sheet',
    subject: 'Chemistry',
    educationSystem: 'GCE',
    level: 'Advanced Level',
    language: 'en',
    fileName: 'organic_mechanisms_2026.pdf',
    isExamPaper: false,
    description:
      'Detailed revision notes on nucleophilic substitution (SN1 and SN2), electrophilic addition to alkenes, free radical substitution, and esterification.',
    contentText:
      'A nucleophile is an electron-pair donor species attracted to positively polarized carbon atoms. ' +
      'An electrophile is an electron-pair acceptor that attacks electron-rich regions such as carbon-carbon double bonds.',
    status: 'under_review',
    uploaderId: 'usr-peer-2',
    uploaderName: 'Amina Ngo',
    createdAt: new Date(Date.now() - 1 * 86400000).toISOString(),
    analysis: {
      detectedLanguage: 'en',
      languageMismatch: false,
      suggestedSubject: 'Chemistry',
      subjectMismatch: false,
      duplicateSimilarity: 0.12,
      wordCount: 540,
      problems: [],
      warnings: [],
    },
  },
];

export const INITIAL_PAST_PAPERS: PastPaper[] = [
  {
    id: 'pp-1',
    title: 'GCE Ordinary Level Mathematics 2024',
    country: 'Cameroon',
    system: 'GCE',
    level: 'O-Level',
    subject: 'Mathematics',
    year: 2024,
    session: 'June',
    summary: 'Paper 2 — Algebra, quadratic equations, coordinate geometry, trigonometry, and mensuration.',
    bookmarked: true,
    downloaded: false,
  },
  {
    id: 'pp-2',
    title: 'GCE Ordinary Level Mathematics 2023',
    country: 'Cameroon',
    system: 'GCE',
    level: 'O-Level',
    subject: 'Mathematics',
    year: 2023,
    session: 'June',
    summary: 'Paper 2 — Vectors, matrices, transformations, and probability distributions.',
    bookmarked: false,
    downloaded: false,
  },
  {
    id: 'pp-3',
    title: 'GCE Advanced Level Physics 2025',
    country: 'Cameroon',
    system: 'GCE',
    level: 'A-Level',
    subject: 'Physics',
    year: 2025,
    session: 'June',
    summary: 'Paper 2 — Mechanics, wave optics, electric fields, electromagnetic induction, and nuclear physics.',
    bookmarked: true,
    downloaded: false,
  },
  {
    id: 'pp-4',
    title: 'Baccalauréat Série C Mathématiques 2024',
    country: 'Cameroon',
    system: 'Francophone',
    level: 'Bac',
    subject: 'Mathématiques',
    year: 2024,
    session: 'Session Normale',
    summary: 'Épreuve de Mathématiques — Nombres complexes, suites numériques, étude de fonctions et calcul intégral.',
    bookmarked: false,
    downloaded: false,
  },
];

export const INITIAL_DECKS: FlashcardDeck[] = [
  {
    id: 'deck-calc-1',
    title: 'Differential Equations & Integration',
    subject: 'Mathematics',
    sourceDocumentId: 'doc-math-1',
    createdAt: new Date(Date.now() - 3 * 86400000).toISOString(),
  },
  {
    id: 'deck-phys-1',
    title: 'Waves & Simple Harmonic Motion',
    subject: 'Physics',
    sourceDocumentId: 'doc-phys-1',
    createdAt: new Date(Date.now() - 2 * 86400000).toISOString(),
  },
];

export const INITIAL_FLASHCARDS: Flashcard[] = [
  {
    id: 'fc-1',
    deckId: 'deck-calc-1',
    front: 'What is an integrating factor for dy/dx + P(x)y = Q(x)?',
    back: 'mu(x) = exp(integral P(x) dx), which turns the left side into d/dx[mu(x) * y].',
    easeFactor: 2.5,
    intervalDays: 1,
    repetitions: 1,
    nextReviewAt: new Date(Date.now() - 3600000).toISOString(),
    lastState: 'known',
  },
  {
    id: 'fc-2',
    deckId: 'deck-calc-1',
    front: 'State the Integration by Parts formula.',
    back: 'integral(u dv) = u*v - integral(v du)',
    easeFactor: 2.5,
    intervalDays: 0,
    repetitions: 0,
    nextReviewAt: new Date(Date.now() - 3600000).toISOString(),
  },
  {
    id: 'fc-3',
    deckId: 'deck-phys-1',
    front: 'Define coherent wave sources.',
    back: 'Wave sources that maintain a constant phase difference and identical frequency.',
    easeFactor: 2.5,
    intervalDays: 0,
    repetitions: 0,
    nextReviewAt: new Date(Date.now() - 3600000).toISOString(),
  },
  {
    id: 'fc-4',
    deckId: 'deck-phys-1',
    front: 'What defines Simple Harmonic Motion (SHM)?',
    back: 'Acceleration is directly proportional to displacement from equilibrium and always directed toward it (a = -w^2 x).',
    easeFactor: 2.36,
    intervalDays: 1,
    repetitions: 1,
    nextReviewAt: new Date(Date.now() - 1800000).toISOString(),
    lastState: 'uncertain',
  },
];

export const INITIAL_QUIZZES: Quiz[] = [
  {
    id: 'quiz-math-1',
    title: 'Differential Equations Checkpoint',
    subject: 'Mathematics',
    difficulty: 'medium',
    createdAt: new Date(Date.now() - 2 * 86400000).toISOString(),
    questions: [
      {
        id: 'qm-1',
        subject: 'Mathematics',
        prompt: 'Which integrating factor solves dy/dx + (2/x)y = x^2 for x > 0?',
        options: ['x^2', '2 ln(x)', 'e^(2x)', '1 / x^2'],
        correctIndex: 0,
        explanation: 'exp(integral 2/x dx) = exp(2 ln x) = x^2.',
      },
      {
        id: 'qm-2',
        subject: 'Mathematics',
        prompt: 'What is the derivative of ln(3x^2 + 1)?',
        options: ['6x / (3x^2 + 1)', '1 / (3x^2 + 1)', '6x ln(3x^2 + 1)', '3x / (3x^2 + 1)'],
        correctIndex: 0,
        explanation: 'By the chain rule, d/dx[ln(u)] = u\' / u = 6x / (3x^2 + 1).',
      },
      {
        id: 'qm-3',
        subject: 'Mathematics',
        prompt: 'When applying integration by parts to integral(x e^x dx), which choice of u is most efficient?',
        options: ['u = x', 'u = e^x', 'u = x e^x', 'u = 1'],
        correctIndex: 0,
        explanation: 'Choosing u = x simplifies du = dx while dv = e^x dx integrates easily to v = e^x.',
      },
    ],
  },
];

export const INITIAL_QUIZ_ATTEMPTS: QuizAttempt[] = [
  {
    id: 'qa-1',
    quizId: 'quiz-math-1',
    subject: 'Mathematics',
    title: 'Differential Equations Checkpoint',
    answers: { 'qm-1': 0, 'qm-2': 0, 'qm-3': 1 },
    score: 67,
    correctCount: 2,
    totalCount: 3,
    submittedAt: new Date(Date.now() - 2 * 86400000).toISOString(),
  },
];

export const SUBSCRIPTION_PLANS: SubscriptionPlan[] = [
  {
    code: 'student_monthly',
    name: 'Student Monthly',
    description: 'Unlimited past paper downloads and AI tutoring. Cancel anytime.',
    tier: 'student',
    amountMinor: 2500,
    currency: 'XAF',
    billingCycle: 'monthly',
    features: ['Unlimited past paper downloads', 'Unlimited AI Tutor chat & vision', 'Unlimited mock exams'],
  },
  {
    code: 'student_quarterly',
    name: 'Student Quarterly',
    description: 'Save 15% over a full exam term.',
    tier: 'student',
    amountMinor: 6375,
    currency: 'XAF',
    billingCycle: 'quarterly',
    features: ['All Student Monthly features', '15% quarterly savings', 'Priority document validation'],
  },
  {
    code: 'premium_yearly',
    name: 'Premium Yearly',
    description: 'Best value for full-year exam preparation plus priority support.',
    tier: 'premium',
    amountMinor: 20000,
    currency: 'XAF',
    billingCycle: 'yearly',
    features: ['Unlimited downloads & AI features', 'Multi-subject mock exam analytics', 'Priority support & early access'],
  },
];
