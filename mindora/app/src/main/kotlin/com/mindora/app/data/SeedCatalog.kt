package com.mindora.app.data

object SeedCatalog {

    val subjectTopics: Map<String, List<String>> = mapOf(
        "Mathematics" to listOf(
            "Algebra & Quadratics",
            "Trigonometry",
            "Differentiation",
            "Integration",
            "Differential Equations",
            "Vectors & Matrices",
            "Probability & Statistics"
        ),
        "Physics" to listOf(
            "Kinematics & Dynamics",
            "Waves & Optics",
            "Electricity & Circuits",
            "Gravitational & Electric Fields",
            "Thermodynamics",
            "Quantum & Nuclear Physics"
        ),
        "Chemistry" to listOf(
            "Atomic Structure & Bonding",
            "Stoichiometry & Moles",
            "Chemical Energetics",
            "Reaction Kinetics",
            "Equilibrium & Acids",
            "Organic Chemistry"
        ),
        "Biology" to listOf(
            "Cell Structure & Transport",
            "Enzymes & Metabolism",
            "Genetics & Inheritance",
            "Human Physiology",
            "Ecology & Ecosystems"
        ),
        "Computer Science" to listOf(
            "Data Structures & Algorithms",
            "Boolean Logic & Gates",
            "Computer Architecture",
            "Database Normalization",
            "Networking & Security"
        ),
        "Economics" to listOf(
            "Supply & Demand Elasticity",
            "Market Structures",
            "Macroeconomic Indicators",
            "Monetary & Fiscal Policy",
            "International Trade"
        ),
        "Mathématiques" to listOf(
            "Suites numériques",
            "Étude de fonctions",
            "Nombres complexes",
            "Probabilités conditionnelles",
            "Géométrie dans l'espace"
        ),
        "English" to listOf(
            "Reading Comprehension",
            "Summary Writing",
            "Grammar & Syntax",
            "Argumentative Essay"
        ),
        "French" to listOf(
            "Compréhension de texte",
            "Dissertation",
            "Grammaire et conjugaison",
            "Analyse littéraire"
        )
    )

    fun initialPlans(): List<StudyPlan> {
        val now = System.currentTimeMillis()
        val day = 86_400_000L
        val planId = "plan-gce-al"
        return listOf(
            StudyPlan(
                id = planId,
                planType = "exam",
                title = "GCE Advanced Level — Science",
                subject = "Mathematics",
                examSystem = "GCE",
                examLevel = "Advanced Level",
                targetDateMillis = now + 42L * day,
                dailyMinutes = 45,
                isActive = true,
                sessions = listOf(
                    StudySession(
                        id = "sess-1",
                        planId = planId,
                        title = "Integration by Parts & Substitution",
                        subject = "Mathematics",
                        topic = "Integration",
                        objective = "Master u-substitution and integration by parts on past GCE Paper 2 problems.",
                        scheduledForMillis = now + 3_600_000L,
                        durationMinutes = 45,
                        status = "scheduled"
                    ),
                    StudySession(
                        id = "sess-2",
                        planId = planId,
                        title = "First-Order Differential Equations",
                        subject = "Mathematics",
                        topic = "Differential Equations",
                        objective = "Solve separable ODEs and apply initial boundary conditions.",
                        scheduledForMillis = now + day,
                        durationMinutes = 40,
                        status = "scheduled"
                    ),
                    StudySession(
                        id = "sess-3",
                        planId = planId,
                        title = "Simple Harmonic Motion & Waves",
                        subject = "Physics",
                        topic = "Waves & Optics",
                        objective = "Derive phase velocity, standing wave nodes, and Doppler shift equations.",
                        scheduledForMillis = now + 2 * day,
                        durationMinutes = 45,
                        status = "scheduled"
                    ),
                    StudySession(
                        id = "sess-4",
                        planId = planId,
                        title = "First Law of Thermodynamics",
                        subject = "Physics",
                        topic = "Thermodynamics",
                        objective = "Analyze isothermal vs adiabatic PV diagrams.",
                        scheduledForMillis = now - day,
                        durationMinutes = 35,
                        status = "completed"
                    ),
                    StudySession(
                        id = "sess-5",
                        planId = planId,
                        title = "Chain Rule & Implicit Differentiation",
                        subject = "Mathematics",
                        topic = "Differentiation",
                        objective = "Differentiate composite and parametric equations cleanly.",
                        scheduledForMillis = now - 2 * day,
                        durationMinutes = 40,
                        status = "completed"
                    )
                )
            ),
            StudyPlan(
                id = "plan-cs",
                planType = "subject",
                title = "Algorithms & Logic Deep Dive",
                subject = "Computer Science",
                examSystem = "GCE",
                examLevel = "Advanced Level",
                targetDateMillis = now + 28L * day,
                dailyMinutes = 30,
                isActive = true,
                sessions = listOf(
                    StudySession(
                        id = "sess-cs-1",
                        planId = "plan-cs",
                        title = "Binary Search & Sorting Complexity",
                        subject = "Computer Science",
                        topic = "Data Structures & Algorithms",
                        objective = "Compare Big-O time/space complexity for merge sort, quicksort, and binary search.",
                        scheduledForMillis = now + day,
                        durationMinutes = 30,
                        status = "scheduled"
                    ),
                    StudySession(
                        id = "sess-cs-2",
                        planId = "plan-cs",
                        title = "De Morgan's Laws & Karnaugh Maps",
                        subject = "Computer Science",
                        topic = "Boolean Logic & Gates",
                        objective = "Simplify 4-variable Boolean expressions using K-maps.",
                        scheduledForMillis = now + 2 * day,
                        durationMinutes = 30,
                        status = "scheduled"
                    )
                )
            )
        )
    }

    fun initialDecks(): List<Deck> {
        val now = System.currentTimeMillis()
        return listOf(
            Deck(
                id = "deck-calc",
                title = "GCE A-Level Calculus Essentials",
                subject = "Mathematics",
                description = "Core differentiation, integration, and ODE rules",
                cards = listOf(
                    Flashcard(
                        id = "fc-1",
                        deckId = "deck-calc",
                        front = "What is the derivative of xⁿ with respect to x?",
                        back = "n · xⁿ⁻¹ (Power Rule)",
                        nextReviewAtMillis = now - 1000L
                    ),
                    Flashcard(
                        id = "fc-2",
                        deckId = "deck-calc",
                        front = "State the Integration by Parts formula.",
                        back = "∫ u dv = u·v − ∫ v du",
                        nextReviewAtMillis = now - 1000L
                    ),
                    Flashcard(
                        id = "fc-3",
                        deckId = "deck-calc",
                        front = "What is ∫ (1 / x) dx?",
                        back = "ln|x| + C",
                        nextReviewAtMillis = now - 1000L
                    ),
                    Flashcard(
                        id = "fc-4",
                        deckId = "deck-calc",
                        front = "When is a stationary point a local minimum?",
                        back = "When f'(x) = 0 and f''(x) > 0.",
                        nextReviewAtMillis = now - 1000L
                    )
                )
            ),
            Deck(
                id = "deck-phys",
                title = "Physics: Mechanics & Waves",
                subject = "Physics",
                description = "Newton's laws, energy conservation, and wave optics",
                cards = listOf(
                    Flashcard(
                        id = "fc-5",
                        deckId = "deck-phys",
                        front = "State the wave equation relating speed v, frequency f, and wavelength λ.",
                        back = "v = f · λ",
                        nextReviewAtMillis = now - 1000L
                    ),
                    Flashcard(
                        id = "fc-6",
                        deckId = "deck-phys",
                        front = "What is the condition for constructive interference?",
                        back = "Path difference = nλ (where n = 0, 1, 2, ...).",
                        nextReviewAtMillis = now - 1000L
                    ),
                    Flashcard(
                        id = "fc-7",
                        deckId = "deck-phys",
                        front = "Define simple harmonic motion (SHM).",
                        back = "Motion where acceleration is directly proportional to displacement from equilibrium and directed towards it: a = −ω²x.",
                        nextReviewAtMillis = now - 1000L
                    )
                )
            ),
            Deck(
                id = "deck-bac",
                title = "Bac Terminale — Probabilités",
                subject = "Mathématiques",
                description = "Formules de Bayes, loi binomiale et variables aléatoires",
                cards = listOf(
                    Flashcard(
                        id = "fc-8",
                        deckId = "deck-bac",
                        front = "Quelle est la formule de la probabilité conditionnelle P_B(A) ?",
                        back = "P_B(A) = P(A ∩ B) / P(B), avec P(B) > 0.",
                        nextReviewAtMillis = now - 1000L
                    ),
                    Flashcard(
                        id = "fc-9",
                        deckId = "deck-bac",
                        front = "Espérance et variance d'une loi binomiale B(n, p) ?",
                        back = "E(X) = n·p et V(X) = n·p·(1 − p).",
                        nextReviewAtMillis = now - 1000L
                    )
                )
            )
        )
    }

    fun initialPastPapers(): List<PastPaper> = listOf(
        PastPaper(
            id = "paper-gce-ol-math-2024",
            title = "GCE Ordinary Level Mathematics 2024",
            subject = "Mathematics",
            examSystem = "GCE",
            examLevel = "O-Level",
            examYear = 2024,
            session = "June",
            language = "en",
            fileSizeLabel = "1.4 MB",
            downloadCount = 1420,
            isUnlocked = true,
            sampleQuestions = listOf(
                "1. Solve the simultaneous equations: 2x + 3y = 13 and x − y = −1.",
                "2. A circle has radius 7 cm. Calculate the area of a sector with angle 120° (take π = 22/7).",
                "3. Factorize completely: 3x² − 12y²."
            )
        ),
        PastPaper(
            id = "paper-gce-al-phys-2025",
            title = "GCE Advanced Level Physics Paper 2",
            subject = "Physics",
            examSystem = "GCE",
            examLevel = "A-Level",
            examYear = 2025,
            session = "June",
            language = "en",
            fileSizeLabel = "2.1 MB",
            downloadCount = 980,
            isUnlocked = false,
            sampleQuestions = listOf(
                "1. Derive an expression for the escape velocity from a planet of mass M and radius R.",
                "2. Explain the photoelectric effect and why classical wave theory fails to predict threshold frequency.",
                "3. A capacitor of 470 µF is charged to 12 V and discharged through a 10 kΩ resistor. Find the time constant."
            )
        ),
        PastPaper(
            id = "paper-bac-math-2024",
            title = "Baccalauréat Série C — Mathématiques",
            subject = "Mathématiques",
            examSystem = "Francophone",
            examLevel = "Bac",
            examYear = 2024,
            session = "Session Normale",
            language = "fr",
            fileSizeLabel = "1.8 MB",
            downloadCount = 1150,
            isUnlocked = false,
            sampleQuestions = listOf(
                "Exercice 1 : On considère la suite (u_n) définie par u_0 = 2 et u_{n+1} = (1/2)u_n + 3. Démontrer par récurrence que u_n < 6.",
                "Exercice 2 : Résoudre dans ℂ l'équation z² − 4z + 8 = 0 et écrire les solutions sous forme exponentielle."
            )
        ),
        PastPaper(
            id = "paper-bepc-2024",
            title = "BEPC — Mathématiques & Physique",
            subject = "Mathématiques",
            examSystem = "Francophone",
            examLevel = "BEPC",
            examYear = 2024,
            session = "Juin",
            language = "fr",
            fileSizeLabel = "1.1 MB",
            downloadCount = 875,
            isUnlocked = false,
            sampleQuestions = listOf(
                "1. Calculer le PGCD de 420 et 252 par l'algorithme d'Euclide.",
                "2. Un triangle ABC est rectangle en A avec AB = 6 cm et AC = 8 cm. Calculer BC et sin(B)."
            )
        ),
        PastPaper(
            id = "paper-gce-al-cs-2024",
            title = "GCE Advanced Level Computer Science",
            subject = "Computer Science",
            examSystem = "GCE",
            examLevel = "A-Level",
            examYear = 2024,
            session = "June",
            language = "en",
            fileSizeLabel = "1.6 MB",
            downloadCount = 640,
            isUnlocked = true,
            sampleQuestions = listOf(
                "1. Convert the decimal number −45 into 8-bit two's complement binary.",
                "2. Trace the quicksort algorithm on the array [18, 7, 24, 3, 12] showing pivot partitions.",
                "3. Normalize a given unnormalized table of student enrollments into 3NF."
            )
        )
    )

    fun initialDocuments(): List<ContributedDocument> = listOf(
        ContributedDocument(
            id = "doc-ode-notes",
            title = "Differential Equations & Integration Summary",
            subject = "Mathematics",
            examSystem = "GCE",
            examLevel = "A-Level",
            description = "Comprehensive revision sheet covering separable ODEs, integrating factors, u-substitution, and integration by parts.",
            contentText = "Differential equations relate a function to its derivatives. A first-order separable ODE has the form dy/dx = g(x)h(y), solved by separating variables ∫(1/h(y))dy = ∫g(x)dx. Integration by parts uses ∫u dv = uv − ∫v du (LIATE rule: Logarithmic, Inverse trig, Algebraic, Trigonometric, Exponential). The derivative of x^n is n*x^(n-1).",
            fileName = "gce_al_differential_equations.pdf",
            status = "approved",
            creditsAwarded = 5
        ),
        ContributedDocument(
            id = "doc-phys-shm",
            title = "Waves, Interference & SHM Formula Guide",
            subject = "Physics",
            examSystem = "GCE",
            examLevel = "A-Level",
            description = "Key derivations and worked examples for simple harmonic motion, Young's double slit, and standing waves.",
            contentText = "Simple Harmonic Motion (SHM) obeys a = -omega^2 * x. Maximum velocity v_max = omega * A. In Young's double slit experiment, fringe separation w = lambda * D / a. Wave speed v = f * lambda.",
            fileName = "physics_waves_shm.pdf",
            status = "approved",
            creditsAwarded = 5
        )
    )

    fun questionBankFor(subject: String): List<MockQuestion> {
        return when (subject) {
            "Physics" -> listOf(
                MockQuestion(
                    id = "pq-1",
                    position = 1,
                    topic = "Waves & Optics",
                    questionType = "mcq",
                    prompt = "A wave of frequency 500 Hz travels at 340 m/s. What is its wavelength?",
                    options = listOf(
                        MockQuestionOption("A", "0.68 m"),
                        MockQuestionOption("B", "1.47 m"),
                        MockQuestionOption("C", "170 m"),
                        MockQuestionOption("D", "0.34 m")
                    ),
                    correctAnswer = "A",
                    explanation = "Using v = fλ, λ = v / f = 340 / 500 = 0.68 m."
                ),
                MockQuestion(
                    id = "pq-2",
                    position = 2,
                    topic = "Kinematics & Dynamics",
                    questionType = "mcq",
                    prompt = "An object starts from rest and accelerates uniformly at 4 m/s² for 5 s. Distance covered is:",
                    options = listOf(
                        MockQuestionOption("A", "20 m"),
                        MockQuestionOption("B", "40 m"),
                        MockQuestionOption("C", "50 m"),
                        MockQuestionOption("D", "100 m")
                    ),
                    correctAnswer = "C",
                    explanation = "s = ut + ½at² = 0 + 0.5 × 4 × 5² = 50 m."
                ),
                MockQuestion(
                    id = "pq-3",
                    position = 3,
                    topic = "Electricity & Circuits",
                    questionType = "true_false",
                    prompt = "In a parallel circuit, the potential difference across each branch is identical.",
                    options = listOf(
                        MockQuestionOption("True", "True"),
                        MockQuestionOption("False", "False")
                    ),
                    correctAnswer = "True",
                    explanation = "Parallel branches share the same two nodes, so the voltage across each branch is equal."
                ),
                MockQuestion(
                    id = "pq-4",
                    position = 4,
                    topic = "Thermodynamics",
                    questionType = "mcq",
                    prompt = "During an isothermal expansion of an ideal gas, which quantity remains constant?",
                    options = listOf(
                        MockQuestionOption("A", "Pressure"),
                        MockQuestionOption("B", "Volume"),
                        MockQuestionOption("C", "Internal energy"),
                        MockQuestionOption("D", "Entropy")
                    ),
                    correctAnswer = "C",
                    explanation = "For an ideal gas, internal energy U depends only on temperature T. Isothermal means constant T, so ΔU = 0."
                ),
                MockQuestion(
                    id = "pq-5",
                    position = 5,
                    topic = "Quantum & Nuclear Physics",
                    questionType = "mcq",
                    prompt = "Increasing the intensity of incident light above threshold frequency increases:",
                    options = listOf(
                        MockQuestionOption("A", "Maximum kinetic energy of photoelectrons"),
                        MockQuestionOption("B", "Work function of the metal"),
                        MockQuestionOption("C", "Rate of emission of photoelectrons"),
                        MockQuestionOption("D", "Stopping potential")
                    ),
                    correctAnswer = "C",
                    explanation = "Higher intensity means more photons per second, releasing more photoelectrons per second (higher photoelectric current)."
                )
            )
            "Computer Science" -> listOf(
                MockQuestion(
                    id = "csq-1",
                    position = 1,
                    topic = "Data Structures & Algorithms",
                    questionType = "mcq",
                    prompt = "What is the worst-case time complexity of binary search on a sorted array of n elements?",
                    options = listOf(
                        MockQuestionOption("A", "O(1)"),
                        MockQuestionOption("B", "O(log n)"),
                        MockQuestionOption("C", "O(n)"),
                        MockQuestionOption("D", "O(n log n)")
                    ),
                    correctAnswer = "B",
                    explanation = "Binary search halves the search interval at each comparison, giving O(log n) worst-case time."
                ),
                MockQuestion(
                    id = "csq-2",
                    position = 2,
                    topic = "Boolean Logic & Gates",
                    questionType = "mcq",
                    prompt = "According to De Morgan's theorem, NOT (A AND B) is equivalent to:",
                    options = listOf(
                        MockQuestionOption("A", "(NOT A) AND (NOT B)"),
                        MockQuestionOption("B", "(NOT A) OR (NOT B)"),
                        MockQuestionOption("C", "A OR B"),
                        MockQuestionOption("D", "A XOR B")
                    ),
                    correctAnswer = "B",
                    explanation = "¬(A ∧ B) ≡ (¬A) ∨ (¬B)."
                ),
                MockQuestion(
                    id = "csq-3",
                    position = 3,
                    topic = "Database Normalization",
                    questionType = "true_false",
                    prompt = "A table in Third Normal Form (3NF) must have no transitive dependencies on non-key attributes.",
                    options = listOf(
                        MockQuestionOption("True", "True"),
                        MockQuestionOption("False", "False")
                    ),
                    correctAnswer = "True",
                    explanation = "3NF requires 2NF plus removal of all transitive functional dependencies among non-prime attributes."
                ),
                MockQuestion(
                    id = "csq-4",
                    position = 4,
                    topic = "Data Structures & Algorithms",
                    questionType = "mcq",
                    prompt = "Which data structure operates on a Last-In, First-Out (LIFO) principle?",
                    options = listOf(
                        MockQuestionOption("A", "Queue"),
                        MockQuestionOption("B", "Stack"),
                        MockQuestionOption("C", "Hash Table"),
                        MockQuestionOption("D", "Binary Heap")
                    ),
                    correctAnswer = "B",
                    explanation = "A stack pushes and pops elements from the top, enforcing LIFO order."
                )
            )
            else -> listOf(
                MockQuestion(
                    id = "mq-1",
                    position = 1,
                    topic = "Differentiation",
                    questionType = "mcq",
                    prompt = "What is the derivative of f(x) = 3x⁴ − 5x + 7?",
                    options = listOf(
                        MockQuestionOption("A", "12x³ − 5"),
                        MockQuestionOption("B", "12x⁴ − 5"),
                        MockQuestionOption("C", "3x³ − 5"),
                        MockQuestionOption("D", "12x³ + 7")
                    ),
                    correctAnswer = "A",
                    explanation = "Applying the power rule term by term: d/dx(3x⁴) = 12x³, d/dx(−5x) = −5, d/dx(7) = 0."
                ),
                MockQuestion(
                    id = "mq-2",
                    position = 2,
                    topic = "Integration",
                    questionType = "mcq",
                    prompt = "Evaluate the definite integral ∫₀² 3x² dx.",
                    options = listOf(
                        MockQuestionOption("A", "4"),
                        MockQuestionOption("B", "6"),
                        MockQuestionOption("C", "8"),
                        MockQuestionOption("D", "12")
                    ),
                    correctAnswer = "C",
                    explanation = "Antiderivative of 3x² is x³. Evaluating from 0 to 2 gives 2³ − 0³ = 8."
                ),
                MockQuestion(
                    id = "mq-3",
                    position = 3,
                    topic = "Differential Equations",
                    questionType = "mcq",
                    prompt = "What is the general solution of dy/dx = 2y?",
                    options = listOf(
                        MockQuestionOption("A", "y = Ce^(2x)"),
                        MockQuestionOption("B", "y = 2x + C"),
                        MockQuestionOption("C", "y = Cx²"),
                        MockQuestionOption("D", "y = e^(−2x)")
                    ),
                    correctAnswer = "A",
                    explanation = "Separating variables: ∫(1/y)dy = ∫2 dx ⇒ ln|y| = 2x + c ⇒ y = Ce^(2x)."
                ),
                MockQuestion(
                    id = "mq-4",
                    position = 4,
                    topic = "Trigonometry",
                    questionType = "true_false",
                    prompt = "For every real angle θ, sin²(θ) + cos²(θ) = 1.",
                    options = listOf(
                        MockQuestionOption("True", "True"),
                        MockQuestionOption("False", "False")
                    ),
                    correctAnswer = "True",
                    explanation = "This is the fundamental Pythagorean trigonometric identity derived from the unit circle."
                ),
                MockQuestion(
                    id = "mq-5",
                    position = 5,
                    topic = "Algebra & Quadratics",
                    questionType = "mcq",
                    prompt = "If the quadratic equation x² − 6x + k = 0 has equal real roots, what is k?",
                    options = listOf(
                        MockQuestionOption("A", "3"),
                        MockQuestionOption("B", "6"),
                        MockQuestionOption("C", "9"),
                        MockQuestionOption("D", "12")
                    ),
                    correctAnswer = "C",
                    explanation = "Equal roots occur when discriminant b² − 4ac = 0 ⇒ (−6)² − 4(1)(k) = 0 ⇒ 36 = 4k ⇒ k = 9."
                ),
                MockQuestion(
                    id = "mq-6",
                    position = 6,
                    topic = "Probability & Statistics",
                    questionType = "mcq",
                    prompt = "Two fair dice are rolled. What is the probability that the sum is 7?",
                    options = listOf(
                        MockQuestionOption("A", "1/12"),
                        MockQuestionOption("B", "1/6"),
                        MockQuestionOption("C", "1/9"),
                        MockQuestionOption("D", "5/36")
                    ),
                    correctAnswer = "B",
                    explanation = "There are 6 outcomes summing to 7 out of 36 total outcomes: (1,6),(2,5),(3,4),(4,3),(5,2),(6,1) → 6/36 = 1/6."
                )
            )
        }
    }

    fun initialMockExams(): List<MockExam> {
        val mathQs = questionBankFor("Mathematics")
        return listOf(
            MockExam(
                id = "exam-math-sample",
                title = "GCE A-Level Calculus Practice",
                subject = "Mathematics",
                academicLevel = "GCE_AL",
                difficulty = "medium",
                durationMinutes = 20,
                status = "ready",
                questions = mathQs
            ),
            MockExam(
                id = "exam-phys-graded",
                title = "Physics Diagnostic Test",
                subject = "Physics",
                academicLevel = "GCE_AL",
                difficulty = "medium",
                durationMinutes = 15,
                status = "graded",
                questions = questionBankFor("Physics"),
                answers = mapOf(
                    "pq-1" to "A",
                    "pq-2" to "C",
                    "pq-3" to "True",
                    "pq-4" to "A",
                    "pq-5" to "C"
                ),
                score = 80.0,
                correctCount = 4,
                wrongCount = 1,
                skippedCount = 0,
                feedbackSummary = "Strong grasp of waves, kinematics, and photoelectric effect. Review ideal gas internal energy under isothermal processes."
            )
        )
    }

    fun initialStudyGroups(): List<StudyGroup> {
        val now = System.currentTimeMillis()
        return listOf(
            StudyGroup(
                id = "grp-gce-math",
                name = "GCE A-Level Mathematics Prep",
                subject = "Mathematics",
                examLevel = "A-Level",
                memberCount = 24,
                messages = listOf(
                    GroupMessage(
                        id = "gm-1",
                        senderName = "Nadine K.",
                        content = "Did anyone finish Question 4 from the 2024 Paper 2 on differential equations?",
                        isMe = false,
                        sentAtMillis = now - 3_600_000L
                    ),
                    GroupMessage(
                        id = "gm-2",
                        senderName = "Samuel T.",
                        content = "Yes! Separate variables first, then use partial fractions before integrating.",
                        isMe = false,
                        sentAtMillis = now - 1_800_000L
                    )
                )
            ),
            StudyGroup(
                id = "grp-bac-c",
                name = "Terminale C — Entraide Sciences",
                subject = "Mathématiques & Physique",
                examLevel = "Baccalauréat",
                memberCount = 19,
                messages = listOf(
                    GroupMessage(
                        id = "gm-3",
                        senderName = "Clara M.",
                        content = "On révise les suites numériques et les nombres complexes ce soir à 19h.",
                        isMe = false,
                        sentAtMillis = now - 5_400_000L
                    )
                )
            )
        )
    }
}
