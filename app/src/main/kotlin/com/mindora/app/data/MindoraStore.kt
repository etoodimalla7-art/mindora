package com.mindora.app.data

import android.content.Context
import android.content.SharedPreferences
import com.mindora.app.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

data class MindoraState(
    val isAuthenticated: Boolean = true,
    val profile: UserProfile = UserProfile(),
    val themeMode: ThemeModeSetting = ThemeModeSetting.SYSTEM,
    val language: AppLanguage = AppLanguage.EN,
    val streakDays: Int = 5,
    val creditsBalance: Int = 18,
    val plans: List<StudyPlan> = SeedCatalog.initialPlans(),
    val conversations: List<Conversation> = emptyList(),
    val activeConversationId: String? = null,
    val aiSending: Boolean = false,
    val decks: List<Deck> = SeedCatalog.initialDecks(),
    val mockExams: List<MockExam> = SeedCatalog.initialMockExams(),
    val pastPapers: List<PastPaper> = SeedCatalog.initialPastPapers(),
    val documents: List<ContributedDocument> = SeedCatalog.initialDocuments(),
    val studyGroups: List<StudyGroup> = SeedCatalog.initialStudyGroups()
) {
    val activeConversation: Conversation?
        get() = conversations.find { it.id == activeConversationId }

    fun buildDashboard(): DashboardData {
        val allSessions = plans.flatMap { it.sessions }
        val scheduled = allSessions.filter { !it.isCompleted }.sortedBy { it.scheduledForMillis }
        val completed = allSessions.filter { it.isCompleted }.sortedByDescending { it.scheduledForMillis }
        val nextSession = scheduled.firstOrNull()

        val activeExamPlan = plans.firstOrNull { it.isActive && it.planType == "exam" }
            ?: plans.firstOrNull { it.isActive }

        val countdown = activeExamPlan?.let {
            ExamCountdown(
                examName = it.title,
                targetDateMillis = it.targetDateMillis,
                daysRemaining = it.daysRemaining
            )
        }

        val todayFocus = nextSession?.let {
            TodayFocus(
                sessionId = it.id,
                title = it.title,
                subject = it.subject,
                topic = it.topic,
                objective = it.objective,
                durationMinutes = it.durationMinutes
            )
        }

        val totalSessions = allSessions.size.coerceAtLeast(1)
        val completedRatio = completed.size.toFloat() / totalSessions.toFloat()
        val gradedExams = mockExams.filter { it.isGraded && it.score != null }
        val examAvg = if (gradedExams.isNotEmpty()) {
            (gradedExams.mapNotNull { it.score }.average() / 100.0).toFloat()
        } else 0.65f
        val totalCards = decks.sumOf { it.cardCount }.coerceAtLeast(1)
        val reviewedCards = decks.flatMap { it.cards }.count { it.repetitions > 0 }
        val retentionRatio = (0.55f + (reviewedCards.toFloat() / totalCards.toFloat()) * 0.45f).coerceIn(0f, 1f)
        val consistencyRatio = (0.4f + (streakDays.coerceAtMost(14) / 14f) * 0.6f).coerceIn(0f, 1f)
        val knowledgeRatio = (0.5f + completedRatio * 0.5f).coerceIn(0f, 1f)

        val readiness = ((knowledgeRatio * 0.25f + examAvg * 0.3f + retentionRatio * 0.25f + consistencyRatio * 0.2f) * 100f)
            .roundToInt()
            .coerceIn(0, 100)

        val weakTopics = listOf(
            WeakTopic("Mathematics", "Differential Equations", 0.42f),
            WeakTopic("Physics", "Quantum & Nuclear Physics", 0.51f),
            WeakTopic("Computer Science", "Database Normalization", 0.58f)
        )

        val recent = completed.take(4).map {
            RecentActivity(
                sessionId = it.id,
                title = it.title,
                subject = it.subject,
                durationMinutes = it.durationMinutes,
                completedAtMillis = it.scheduledForMillis
            )
        }

        return DashboardData(
            streakDays = streakDays,
            examCountdown = countdown,
            todayFocus = todayFocus,
            readinessScore = readiness,
            readinessBreakdown = ReadinessBreakdown(
                knowledge = knowledgeRatio,
                practice = examAvg,
                retention = retentionRatio,
                consistency = consistencyRatio
            ),
            weakTopics = weakTopics,
            recentActivity = recent
        )
    }
}

class MindoraStore(context: Context) {
    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences("mindora_prefs_v1", Context.MODE_PRIVATE)

    private val _state = MutableStateFlow(loadInitialState())
    val state: StateFlow<MindoraState> = _state.asStateFlow()

    private fun loadInitialState(): MindoraState {
        val raw = prefs.getString("state_json", null)
        if (raw.isNullOrBlank()) return MindoraState()
        return try {
            val j = JSONObject(raw)
            val pJson = j.optJSONObject("profile")
            val profile = if (pJson != null) {
                UserProfile(
                    id = pJson.optString("id", "student-1"),
                    fullName = pJson.optString("fullName", "Alex Mbarga"),
                    email = pJson.optString("email", "alex.mbarga@mindora.edu"),
                    isVerified = pJson.optBoolean("isVerified", true),
                    preferredLanguage = AppLanguage.fromCode(pJson.optString("preferredLanguage", "en")),
                    countryCode = pJson.optString("countryCode", "CM"),
                    educationSystem = pJson.optString("educationSystem", "Anglophone"),
                    level = pJson.optString("level", "GCE Advanced Level"),
                    program = pJson.optString("program", "Science"),
                    subjects = jsonArrayToList(pJson.optJSONArray("subjects")).ifEmpty {
                        listOf("Mathematics", "Physics", "Computer Science")
                    },
                    goal = pJson.optString("goal", "pass_exam"),
                    targetExamDateMillis = pJson.optLong(
                        "targetExamDateMillis",
                        System.currentTimeMillis() + 42L * 86_400_000L
                    ),
                    studyWindows = jsonArrayToList(pJson.optJSONArray("studyWindows")).ifEmpty {
                        listOf("evening")
                    },
                    explanationStyle = pJson.optString("explanationStyle", "standard"),
                    allowNotifications = pJson.optBoolean("allowNotifications", true),
                    onboardingCompleted = pJson.optBoolean("onboardingCompleted", false)
                )
            } else UserProfile()

            val themeMode = ThemeModeSetting.fromId(j.optString("themeMode", "system"))
            val language = AppLanguage.fromCode(j.optString("language", "en"))
            val streakDays = j.optInt("streakDays", 5)
            val creditsBalance = j.optInt("creditsBalance", 18)
            val isAuthenticated = j.optBoolean("isAuthenticated", true)

            val plans = parsePlans(j.optJSONArray("plans")) ?: SeedCatalog.initialPlans()
            val decks = parseDecks(j.optJSONArray("decks")) ?: SeedCatalog.initialDecks()
            val docs = parseDocuments(j.optJSONArray("documents")) ?: SeedCatalog.initialDocuments()
            val exams = parseMockExams(j.optJSONArray("mockExams")) ?: SeedCatalog.initialMockExams()
            val convos = parseConversations(j.optJSONArray("conversations")) ?: emptyList()

            val unlockedPaperIds = jsonArrayToList(j.optJSONArray("unlockedPaperIds")).toSet()
            val papers = SeedCatalog.initialPastPapers().map { p ->
                if (unlockedPaperIds.contains(p.id)) p.copy(isUnlocked = true) else p
            }

            MindoraState(
                isAuthenticated = isAuthenticated,
                profile = profile,
                themeMode = themeMode,
                language = language,
                streakDays = streakDays,
                creditsBalance = creditsBalance,
                plans = plans,
                conversations = convos,
                activeConversationId = convos.firstOrNull()?.id,
                decks = decks,
                mockExams = exams,
                pastPapers = papers,
                documents = docs,
                studyGroups = SeedCatalog.initialStudyGroups()
            )
        } catch (_: Exception) {
            MindoraState()
        }
    }

    private fun persist(s: MindoraState) {
        try {
            val root = JSONObject()
            root.put("isAuthenticated", s.isAuthenticated)
            root.put("themeMode", s.themeMode.id)
            root.put("language", s.language.code)
            root.put("streakDays", s.streakDays)
            root.put("creditsBalance", s.creditsBalance)

            val p = JSONObject().apply {
                put("id", s.profile.id)
                put("fullName", s.profile.fullName)
                put("email", s.profile.email)
                put("isVerified", s.profile.isVerified)
                put("preferredLanguage", s.profile.preferredLanguage.code)
                put("countryCode", s.profile.countryCode)
                put("educationSystem", s.profile.educationSystem)
                put("level", s.profile.level)
                put("program", s.profile.program)
                put("subjects", JSONArray(s.profile.subjects))
                put("goal", s.profile.goal)
                put("targetExamDateMillis", s.profile.targetExamDateMillis)
                put("studyWindows", JSONArray(s.profile.studyWindows))
                put("explanationStyle", s.profile.explanationStyle)
                put("allowNotifications", s.profile.allowNotifications)
                put("onboardingCompleted", s.profile.onboardingCompleted)
            }
            root.put("profile", p)
            root.put("plans", serializePlans(s.plans))
            root.put("decks", serializeDecks(s.decks))
            root.put("documents", serializeDocuments(s.documents))
            root.put("mockExams", serializeMockExams(s.mockExams))
            root.put("conversations", serializeConversations(s.conversations))
            root.put("unlockedPaperIds", JSONArray(s.pastPapers.filter { it.isUnlocked }.map { it.id }))
            prefs.edit().putString("state_json", root.toString()).apply()
        } catch (_: Exception) {
        }
    }

    private fun updateAndPersist(transform: (MindoraState) -> MindoraState) {
        _state.update { current ->
            val next = transform(current)
            persist(next)
            next
        }
    }

    // --- Auth & Onboarding ---

    fun signIn(email: String, fullName: String? = null) {
        updateAndPersist { s ->
            val name = fullName?.takeIf { it.isNotBlank() }
                ?: email.substringBefore("@").replace(".", " ").replaceFirstChar { it.uppercase() }
            s.copy(
                isAuthenticated = true,
                profile = s.profile.copy(
                    email = email.trim(),
                    fullName = name,
                    onboardingCompleted = true
                )
            )
        }
    }

    fun signOut() {
        updateAndPersist { s ->
            s.copy(isAuthenticated = false)
        }
    }

    fun updateProfile(profile: UserProfile) {
        updateAndPersist { s ->
            s.copy(
                profile = profile,
                language = profile.preferredLanguage
            )
        }
    }

    fun setThemeMode(mode: ThemeModeSetting) {
        updateAndPersist { it.copy(themeMode = mode) }
    }

    fun setLanguage(lang: AppLanguage) {
        updateAndPersist { s ->
            s.copy(
                language = lang,
                profile = s.profile.copy(preferredLanguage = lang)
            )
        }
    }

    // --- Planner & Study Sessions ---

    fun completeSession(sessionId: String) {
        updateAndPersist { s ->
            val wasAlreadyDone = s.plans.flatMap { it.sessions }.find { it.id == sessionId }?.isCompleted == true
            val updatedPlans = s.plans.map { plan ->
                plan.copy(
                    sessions = plan.sessions.map { sess ->
                        if (sess.id == sessionId) sess.copy(status = "completed") else sess
                    }
                )
            }
            s.copy(
                plans = updatedPlans,
                streakDays = if (wasAlreadyDone) s.streakDays else s.streakDays + 1
            )
        }
    }

    fun createPlan(
        planType: String,
        title: String,
        subject: String,
        examSystem: String,
        examLevel: String,
        targetDateMillis: Long,
        dailyMinutes: Int
    ): StudyPlan {
        val planId = "plan-${UUID.randomUUID().toString().take(8)}"
        val topics = SeedCatalog.subjectTopics[subject]
            ?: listOf("Core Foundations", "Worked Examples", "Problem Solving", "Exam Practice")
        val now = System.currentTimeMillis()
        val sessions = topics.mapIndexed { idx, topic ->
            StudySession(
                id = "sess-${UUID.randomUUID().toString().take(8)}",
                planId = planId,
                title = "$topic — Practice",
                subject = subject,
                topic = topic,
                objective = "Review key concepts in $topic and solve $examLevel exercises.",
                scheduledForMillis = now + idx.toLong() * 86_400_000L,
                durationMinutes = dailyMinutes,
                status = "scheduled"
            )
        }
        val plan = StudyPlan(
            id = planId,
            planType = planType,
            title = title,
            subject = subject,
            examSystem = examSystem,
            examLevel = examLevel,
            targetDateMillis = targetDateMillis,
            dailyMinutes = dailyMinutes,
            isActive = true,
            sessions = sessions
        )
        updateAndPersist { s -> s.copy(plans = listOf(plan) + s.plans) }
        return plan
    }

    // --- Flashcards (SM-2) ---

    fun createDeck(title: String, subject: String, description: String) {
        val deck = Deck(
            id = "deck-${UUID.randomUUID().toString().take(8)}",
            title = title.trim(),
            subject = subject,
            description = description.ifBlank { "Custom study deck" },
            cards = emptyList()
        )
        updateAndPersist { s -> s.copy(decks = listOf(deck) + s.decks) }
    }

    fun addFlashcard(deckId: String, front: String, back: String) {
        val card = Flashcard(
            id = "fc-${UUID.randomUUID().toString().take(8)}",
            deckId = deckId,
            front = front.trim(),
            back = back.trim(),
            nextReviewAtMillis = System.currentTimeMillis() - 1000L
        )
        updateAndPersist { s ->
            s.copy(
                decks = s.decks.map { d ->
                    if (d.id == deckId) d.copy(cards = d.cards + card) else d
                }
            )
        }
    }

    fun generateFlashcardsForDeck(deckId: String, topic: String) {
        val now = System.currentTimeMillis() - 1000L
        val generated = listOf(
            Flashcard(
                id = "fc-${UUID.randomUUID().toString().take(8)}",
                deckId = deckId,
                front = "Key definition of $topic",
                back = "$topic focuses on fundamental principles, core theorems, and structured problem-solving methods tested in exams.",
                nextReviewAtMillis = now
            ),
            Flashcard(
                id = "fc-${UUID.randomUUID().toString().take(8)}",
                deckId = deckId,
                front = "Common exam pitfall in $topic",
                back = "Always verify boundary conditions, units, and sign conventions before finalizing your solution.",
                nextReviewAtMillis = now
            ),
            Flashcard(
                id = "fc-${UUID.randomUUID().toString().take(8)}",
                deckId = deckId,
                front = "How to verify a result in $topic?",
                back = "Substitute values back into the original equation or test limiting cases.",
                nextReviewAtMillis = now
            )
        )
        updateAndPersist { s ->
            s.copy(
                decks = s.decks.map { d ->
                    if (d.id == deckId) d.copy(cards = d.cards + generated) else d
                }
            )
        }
    }

    fun reviewFlashcard(deckId: String, cardId: String, quality: Int) {
        updateAndPersist { s ->
            s.copy(
                decks = s.decks.map { deck ->
                    if (deck.id != deckId) deck
                    else deck.copy(
                        cards = deck.cards.map { c ->
                            if (c.id == cardId) Sm2Engine.update(c, quality) else c
                        }
                    )
                }
            )
        }
    }

    // --- Mock Exams ---

    fun createMockExam(
        title: String,
        subject: String,
        academicLevel: String,
        difficulty: String,
        questionCount: Int,
        durationMinutes: Int
    ): MockExam {
        val bank = SeedCatalog.questionBankFor(subject)
        val selected = (0 until questionCount).map { idx ->
            val template = bank[idx % bank.size]
            template.copy(
                id = "q-${UUID.randomUUID().toString().take(6)}-$idx",
                position = idx + 1
            )
        }
        val exam = MockExam(
            id = "exam-${UUID.randomUUID().toString().take(8)}",
            title = title.trim(),
            subject = subject,
            academicLevel = academicLevel,
            difficulty = difficulty,
            durationMinutes = durationMinutes,
            status = "ready",
            questions = selected
        )
        updateAndPersist { s -> s.copy(mockExams = listOf(exam) + s.mockExams) }
        return exam
    }

    fun startMockExam(examId: String) {
        updateAndPersist { s ->
            s.copy(
                mockExams = s.mockExams.map { e ->
                    if (e.id == examId && e.isReady) e.copy(status = "in_progress") else e
                }
            )
        }
    }

    fun saveExamAnswer(examId: String, questionId: String, answer: String) {
        updateAndPersist { s ->
            s.copy(
                mockExams = s.mockExams.map { e ->
                    if (e.id == examId) {
                        e.copy(
                            status = if (e.isReady) "in_progress" else e.status,
                            answers = e.answers + (questionId to answer)
                        )
                    } else e
                }
            )
        }
    }

    fun submitMockExam(examId: String) {
        updateAndPersist { s ->
            s.copy(
                mockExams = s.mockExams.map { e ->
                    if (e.id != examId) e
                    else {
                        var correct = 0
                        var wrong = 0
                        var skipped = 0
                        e.questions.forEach { q ->
                            val ans = e.answers[q.id]
                            if (ans.isNullOrBlank()) {
                                skipped++
                            } else if (ans.equals(q.correctAnswer, ignoreCase = true)) {
                                correct++
                            } else {
                                wrong++
                            }
                        }
                        val total = e.questions.size.coerceAtLeast(1)
                        val scorePct = ((correct.toDouble() / total.toDouble()) * 100.0 * 10.0).roundToInt() / 10.0
                        val summary = when {
                            scorePct >= 80 -> "Excellent performance! You have strong mastery across ${e.subject}."
                            scorePct >= 60 -> "Solid effort. Review the missed explanations below to lock in top marks."
                            else -> "Keep practicing! Focus on the topic breakdown below and use flashcards to reinforce core formulas."
                        }
                        e.copy(
                            status = "graded",
                            score = scorePct,
                            correctCount = correct,
                            wrongCount = wrong,
                            skippedCount = skipped,
                            feedbackSummary = summary
                        )
                    }
                }
            )
        }
    }

    // --- Past Papers & Documents ---

    fun unlockPaper(paperId: String): Boolean {
        val current = _state.value
        val paper = current.pastPapers.find { it.id == paperId } ?: return false
        if (paper.isUnlocked) return true
        if (current.creditsBalance < 2) return false
        updateAndPersist { s ->
            s.copy(
                creditsBalance = s.creditsBalance - 2,
                pastPapers = s.pastPapers.map { p ->
                    if (p.id == paperId) p.copy(isUnlocked = true, downloadCount = p.downloadCount + 1) else p
                }
            )
        }
        return true
    }

    fun contributeDocument(
        title: String,
        subject: String,
        examSystem: String,
        examLevel: String,
        description: String,
        contentText: String,
        fileName: String
    ): ContributedDocument {
        val doc = ContributedDocument(
            id = "doc-${UUID.randomUUID().toString().take(8)}",
            title = title.trim(),
            subject = subject,
            examSystem = examSystem,
            examLevel = examLevel,
            description = description.trim(),
            contentText = contentText.trim(),
            fileName = fileName.ifBlank { "${title.lowercase().replace(" ", "_")}.txt" },
            status = "approved",
            creditsAwarded = 5
        )
        updateAndPersist { s ->
            s.copy(
                creditsBalance = s.creditsBalance + 5,
                documents = listOf(doc) + s.documents
            )
        }
        return doc
    }

    // --- Study Groups ---

    fun sendGroupMessage(groupId: String, content: String) {
        val trimmed = content.trim()
        if (trimmed.isEmpty()) return
        val sender = _state.value.profile.fullName
        val msg = GroupMessage(
            id = "gm-${UUID.randomUUID().toString().take(8)}",
            senderName = sender,
            content = trimmed,
            isMe = true
        )
        updateAndPersist { s ->
            s.copy(
                studyGroups = s.studyGroups.map { g ->
                    if (g.id == groupId) g.copy(messages = g.messages + msg) else g
                }
            )
        }
    }

    // --- AI Tutor Chat ---

    fun startNewConversation() {
        updateAndPersist { it.copy(activeConversationId = null) }
    }

    fun selectConversation(id: String) {
        updateAndPersist { it.copy(activeConversationId = id) }
    }

    suspend fun sendAiMessage(prompt: String, attachmentLabel: String? = null) {
        val cleanPrompt = prompt.trim()
        if (cleanPrompt.isEmpty() && attachmentLabel == null) return

        val effectivePrompt = if (cleanPrompt.isEmpty()) {
            "Analyze attached study exercise: $attachmentLabel"
        } else cleanPrompt

        val userMsg = ChatMessage(
            id = "msg-${UUID.randomUUID().toString().take(8)}",
            role = "user",
            content = effectivePrompt,
            attachmentLabel = attachmentLabel
        )

        var convId = _state.value.activeConversationId
        if (convId == null) {
            convId = "conv-${UUID.randomUUID().toString().take(8)}"
            val newConv = Conversation(
                id = convId,
                title = effectivePrompt.take(40),
                subject = _state.value.profile.subjects.firstOrNull(),
                messages = listOf(userMsg)
            )
            updateAndPersist { s ->
                s.copy(
                    conversations = listOf(newConv) + s.conversations,
                    activeConversationId = convId,
                    aiSending = true
                )
            }
        } else {
            updateAndPersist { s ->
                s.copy(
                    conversations = s.conversations.map { c ->
                        if (c.id == convId) c.copy(messages = c.messages + userMsg, updatedAtMillis = System.currentTimeMillis())
                        else c
                    },
                    aiSending = true
                )
            }
        }

        val reply = generateTutorReply(effectivePrompt, attachmentLabel)

        updateAndPersist { s ->
            s.copy(
                aiSending = false,
                conversations = s.conversations.map { c ->
                    if (c.id == convId) c.copy(messages = c.messages + reply, updatedAtMillis = System.currentTimeMillis())
                    else c
                }
            )
        }
    }

    private suspend fun generateTutorReply(prompt: String, attachmentLabel: String?): ChatMessage {
        val snapshot = _state.value
        val toolsUsed = mutableListOf<ToolUsage>()

        // 1. Check math calculator tool
        val mathResult = tryEvaluateMath(prompt)
        if (mathResult != null) {
            toolsUsed.add(ToolUsage("Calculator", mathResult.first))
        }

        // 2. Check Course RAG across uploaded/seeded documents
        val matchingDocs = searchCourseDocuments(prompt, snapshot.documents)
        if (matchingDocs.isNotEmpty()) {
            toolsUsed.add(ToolUsage("Course RAG", matchingDocs.first().title))
        }

        // 3. Try Gemini REST API if key is configured
        val apiKey = BuildConfig.GEMINI_API_KEY
        if (apiKey.isNotBlank() && !apiKey.contains("your_", ignoreCase = true)) {
            val geminiText = callGeminiApi(
                apiKey = apiKey,
                prompt = prompt,
                profile = snapshot.profile,
                docContext = matchingDocs.joinToString("\n\n") { "${it.title}: ${it.contentText}" },
                mathHint = mathResult?.let { "${it.first} = ${it.second}" }
            )
            if (!geminiText.isNullOrBlank()) {
                if (toolsUsed.isEmpty()) toolsUsed.add(ToolUsage("AI Tutor", "Gemini"))
                return ChatMessage(
                    id = "msg-${UUID.randomUUID().toString().take(8)}",
                    role = "assistant",
                    content = geminiText,
                    toolsUsed = toolsUsed
                )
            }
        }

        // 4. Grounded intelligent tutor fallback
        val style = snapshot.profile.explanationStyle
        val responseText = buildOfflineTutorResponse(
            prompt = prompt,
            attachmentLabel = attachmentLabel,
            style = style,
            mathResult = mathResult,
            matchingDocs = matchingDocs,
            profile = snapshot.profile
        )
        if (toolsUsed.isEmpty()) toolsUsed.add(ToolUsage("Study Tutor", style.replaceFirstChar { it.uppercase() }))

        return ChatMessage(
            id = "msg-${UUID.randomUUID().toString().take(8)}",
            role = "assistant",
            content = responseText,
            toolsUsed = toolsUsed
        )
    }

    private suspend fun callGeminiApi(
        apiKey: String,
        prompt: String,
        profile: UserProfile,
        docContext: String,
        mathHint: String?
    ): String? = withContext(Dispatchers.IO) {
        try {
            val url = URL("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey")
            val conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                setRequestProperty("Content-Type", "application/json")
                connectTimeout = 10_000
                readTimeout = 15_000
                doOutput = true
            }

            val sysInstruction = buildString {
                append("You are MINDORA, a supportive exam-prep tutor for a ${profile.level} student (${profile.educationSystem} system). ")
                append("Explanation style: ${profile.explanationStyle}. Language: ${profile.preferredLanguage.label}. ")
                if (docContext.isNotBlank()) {
                    append("\nRelevant student course notes:\n$docContext\n")
                }
                if (mathHint != null) {
                    append("\nVerified calculation: $mathHint\n")
                }
            }

            val payload = JSONObject().apply {
                put("contents", JSONArray().apply {
                    put(JSONObject().apply {
                        put("parts", JSONArray().apply {
                            put(JSONObject().apply {
                                put("text", "$sysInstruction\n\nStudent question: $prompt")
                            })
                        })
                    })
                })
            }

            OutputStreamWriter(conn.outputStream).use { it.write(payload.toString()) }
            if (conn.responseCode in 200..299) {
                val resp = conn.inputStream.bufferedReader().readText()
                val json = JSONObject(resp)
                val candidates = json.optJSONArray("candidates")
                val first = candidates?.optJSONObject(0)
                val content = first?.optJSONObject("content")
                val parts = content?.optJSONArray("parts")
                parts?.optJSONObject(0)?.optString("text")?.takeIf { it.isNotBlank() }
            } else null
        } catch (_: Exception) {
            null
        }
    }

    private fun searchCourseDocuments(query: String, docs: List<ContributedDocument>): List<ContributedDocument> {
        val tokens = query.lowercase().split(Regex("[^a-z0-9à-ÿ]+")).filter { it.length >= 4 }
        if (tokens.isEmpty()) return emptyList()
        return docs.filter { doc ->
            val haystack = "${doc.title} ${doc.subject} ${doc.description} ${doc.contentText}".lowercase()
            tokens.any { haystack.contains(it) }
        }
    }

    private fun buildOfflineTutorResponse(
        prompt: String,
        attachmentLabel: String?,
        style: String,
        mathResult: Pair<String, String>?,
        matchingDocs: List<ContributedDocument>,
        profile: UserProfile
    ): String {
        val q = prompt.lowercase()
        val sb = StringBuilder()

        if (mathResult != null) {
            sb.append("Calculated Result: ${mathResult.first} = ${mathResult.second}\n\n")
        }

        if (matchingDocs.isNotEmpty()) {
            val doc = matchingDocs.first()
            sb.append("From your course document \"${doc.title}\":\n${doc.contentText}\n\n")
        }

        when {
            q.contains("derivative") || q.contains("x²") || q.contains("x^2") || q.contains("dérivée") -> {
                sb.append(
                    "Step-by-step derivative of x²:\n" +
                        "1. Apply the Power Rule: d/dx (xⁿ) = n · xⁿ⁻¹.\n" +
                        "2. Here n = 2, so bring 2 in front and reduce the exponent by 1: 2 · x²⁻¹ = 2x.\n" +
                        "3. Geometrically, 2x gives the gradient (slope) of the tangent line to y = x² at any point x."
                )
            }
            q.contains("integration by parts") || q.contains("integrate") || q.contains("integral") -> {
                sb.append(
                    "Integration by Parts Formula: ∫ u dv = u·v − ∫ v du\n\n" +
                        "3 Practice Questions (${profile.level}):\n" +
                        "1. Evaluate ∫ x · eˣ dx  (Hint: let u = x, dv = eˣ dx)\n" +
                        "2. Evaluate ∫ x · cos(x) dx  (Hint: let u = x, dv = cos(x) dx)\n" +
                        "3. Evaluate ∫ ln(x) dx  (Hint: let u = ln(x), dv = 1 dx)\n\n" +
                        "Ask me to walk through any of these 3!"
                )
            }
            q.contains("differential equation") || q.contains("ode") -> {
                sb.append(
                    "How to solve First-Order Separable Differential Equations (dy/dx = g(x)h(y)):\n" +
                        "1. Separate variables so all y terms are on the left and x terms on the right.\n" +
                        "2. Integrate both sides: ∫ (1/h(y)) dy = ∫ g(x) dx + C.\n" +
                        "3. Apply any given initial condition y(x₀) = y₀ to find the constant C."
                )
            }
            attachmentLabel != null -> {
                sb.append(
                    "I received \"$attachmentLabel\". Break the exercise into:\n" +
                        "• Known quantities and boundary conditions\n" +
                        "• Governing theorem or equation\n" +
                        "• Step-by-step substitution and unit check.\n" +
                        "Type the equation or question text here and I will solve it line by line."
                )
            }
            mathResult == null -> {
                val lead = when (style) {
                    "socratic" -> "Let's reason through this together. First, what core principle or formula applies to your question?"
                    "concise" -> "Direct Summary:"
                    else -> "Here is a structured explanation tailored to ${profile.level}:"
                }
                sb.append(
                    "$lead\n\n" +
                        "1. Identify the key concept in \"$prompt\".\n" +
                        "2. Connect it to the syllabus formulas (e.g., conservation laws, calculus rules, or definitions).\n" +
                        "3. Test your understanding by creating a quick 5-question Mock Exam or Flashcard deck in the Learn tab.\n\n" +
                        "Tip: You can also type math expressions like `sqrt(144) + 8*3` or upload your own course notes for RAG answers."
                )
            }
        }
        return sb.toString().trim()
    }

    /**
     * Lightweight safe recursive-descent arithmetic evaluator supporting +, -, *, /, ^, (), sqrt(), sin(), cos().
     */
    private fun tryEvaluateMath(input: String): Pair<String, String>? {
        val candidate = input.trim()
        if (!candidate.matches(Regex("^[0-9.+\\-*/^()\\s a-zA-Z]+$"))) return null
        if (!candidate.any { it.isDigit() }) return null
        if (!candidate.any { it in "+-*/^" || candidate.contains("sqrt(", true) }) return null
        return try {
            val value = MathParser(candidate).parse()
            if (value.isNaN() || value.isInfinite()) null
            else {
                val formatted = if (value % 1.0 == 0.0) value.toLong().toString()
                else String.format("%.4f", value).trimEnd('0').trimEnd('.')
                candidate to formatted
            }
        } catch (_: Exception) {
            null
        }
    }

    private class MathParser(private val str: String) {
        private var pos = -1
        private var ch = 0

        private fun nextChar() {
            ch = if (++pos < str.length) str[pos].code else -1
        }

        private fun eat(charToEat: Int): Boolean {
            while (ch == ' '.code) nextChar()
            if (ch == charToEat) {
                nextChar()
                return true
            }
            return false
        }

        fun parse(): Double {
            nextChar()
            val x = parseExpression()
            if (pos < str.length) throw IllegalArgumentException("Unexpected char")
            return x
        }

        private fun parseExpression(): Double {
            var x = parseTerm()
            while (true) {
                when {
                    eat('+'.code) -> x += parseTerm()
                    eat('-'.code) -> x -= parseTerm()
                    else -> return x
                }
            }
        }

        private fun parseTerm(): Double {
            var x = parseFactor()
            while (true) {
                when {
                    eat('*'.code) -> x *= parseFactor()
                    eat('/'.code) -> x /= parseFactor()
                    else -> return x
                }
            }
        }

        private fun parseFactor(): Double {
            if (eat('+'.code)) return parseFactor()
            if (eat('-'.code)) return -parseFactor()
            var x: Double
            val startPos = pos
            if (eat('('.code)) {
                x = parseExpression()
                if (!eat(')'.code)) throw IllegalArgumentException("Missing )")
            } else if ((ch in '0'.code..'9'.code) || ch == '.'.code) {
                while ((ch in '0'.code..'9'.code) || ch == '.'.code) nextChar()
                x = str.substring(startPos, pos).toDouble()
            } else if (ch in 'a'.code..'z'.code || ch in 'A'.code..'Z'.code) {
                while (ch in 'a'.code..'z'.code || ch in 'A'.code..'Z'.code) nextChar()
                val func = str.substring(startPos, pos).lowercase()
                x = parseFactor()
                x = when (func) {
                    "sqrt" -> sqrt(x)
                    "sin" -> sin(Math.toRadians(x))
                    "cos" -> cos(Math.toRadians(x))
                    else -> throw IllegalArgumentException("Unknown func: $func")
                }
            } else {
                throw IllegalArgumentException("Unexpected char")
            }
            if (eat('^'.code)) x = x.pow(parseFactor())
            return x
        }
    }

    // --- JSON helpers ---

    private fun jsonArrayToList(arr: JSONArray?): List<String> {
        if (arr == null) return emptyList()
        return (0 until arr.length()).mapNotNull { arr.optString(it).takeIf { s -> s.isNotEmpty() } }
    }

    private fun serializePlans(plans: List<StudyPlan>): JSONArray = JSONArray().apply {
        plans.forEach { p ->
            put(JSONObject().apply {
                put("id", p.id)
                put("planType", p.planType)
                put("title", p.title)
                put("subject", p.subject)
                put("examSystem", p.examSystem)
                put("examLevel", p.examLevel)
                put("targetDateMillis", p.targetDateMillis)
                put("dailyMinutes", p.dailyMinutes)
                put("isActive", p.isActive)
                put("sessions", JSONArray().apply {
                    p.sessions.forEach { s ->
                        put(JSONObject().apply {
                            put("id", s.id)
                            put("planId", s.planId)
                            put("title", s.title)
                            put("subject", s.subject)
                            put("topic", s.topic)
                            put("objective", s.objective)
                            put("scheduledForMillis", s.scheduledForMillis)
                            put("durationMinutes", s.durationMinutes)
                            put("status", s.status)
                        })
                    }
                })
            })
        }
    }

    private fun parsePlans(arr: JSONArray?): List<StudyPlan>? {
        if (arr == null) return null
        return (0 until arr.length()).map { i ->
            val p = arr.getJSONObject(i)
            val sArr = p.optJSONArray("sessions")
            val sessions = if (sArr != null) {
                (0 until sArr.length()).map { j ->
                    val s = sArr.getJSONObject(j)
                    StudySession(
                        id = s.getString("id"),
                        planId = s.getString("planId"),
                        title = s.getString("title"),
                        subject = s.getString("subject"),
                        topic = s.getString("topic"),
                        objective = s.getString("objective"),
                        scheduledForMillis = s.getLong("scheduledForMillis"),
                        durationMinutes = s.getInt("durationMinutes"),
                        status = s.getString("status")
                    )
                }
            } else emptyList()
            StudyPlan(
                id = p.getString("id"),
                planType = p.getString("planType"),
                title = p.getString("title"),
                subject = p.getString("subject"),
                examSystem = p.getString("examSystem"),
                examLevel = p.getString("examLevel"),
                targetDateMillis = p.getLong("targetDateMillis"),
                dailyMinutes = p.getInt("dailyMinutes"),
                isActive = p.getBoolean("isActive"),
                sessions = sessions
            )
        }
    }

    private fun serializeDecks(decks: List<Deck>): JSONArray = JSONArray().apply {
        decks.forEach { d ->
            put(JSONObject().apply {
                put("id", d.id)
                put("title", d.title)
                put("subject", d.subject)
                put("description", d.description)
                put("cards", JSONArray().apply {
                    d.cards.forEach { c ->
                        put(JSONObject().apply {
                            put("id", c.id)
                            put("deckId", c.deckId)
                            put("front", c.front)
                            put("back", c.back)
                            put("easeFactor", c.easeFactor)
                            put("intervalDays", c.intervalDays)
                            put("repetitions", c.repetitions)
                            put("nextReviewAtMillis", c.nextReviewAtMillis)
                        })
                    }
                })
            })
        }
    }

    private fun parseDecks(arr: JSONArray?): List<Deck>? {
        if (arr == null) return null
        return (0 until arr.length()).map { i ->
            val d = arr.getJSONObject(i)
            val cArr = d.optJSONArray("cards")
            val cards = if (cArr != null) {
                (0 until cArr.length()).map { j ->
                    val c = cArr.getJSONObject(j)
                    Flashcard(
                        id = c.getString("id"),
                        deckId = c.getString("deckId"),
                        front = c.getString("front"),
                        back = c.getString("back"),
                        easeFactor = c.getDouble("easeFactor"),
                        intervalDays = c.getInt("intervalDays"),
                        repetitions = c.getInt("repetitions"),
                        nextReviewAtMillis = c.getLong("nextReviewAtMillis")
                    )
                }
            } else emptyList()
            Deck(
                id = d.getString("id"),
                title = d.getString("title"),
                subject = d.getString("subject"),
                description = d.getString("description"),
                cards = cards
            )
        }
    }

    private fun serializeDocuments(docs: List<ContributedDocument>): JSONArray = JSONArray().apply {
        docs.forEach { doc ->
            put(JSONObject().apply {
                put("id", doc.id)
                put("title", doc.title)
                put("subject", doc.subject)
                put("examSystem", doc.examSystem)
                put("examLevel", doc.examLevel)
                put("description", doc.description)
                put("contentText", doc.contentText)
                put("fileName", doc.fileName)
                put("status", doc.status)
                put("creditsAwarded", doc.creditsAwarded)
                put("createdAtMillis", doc.createdAtMillis)
            })
        }
    }

    private fun parseDocuments(arr: JSONArray?): List<ContributedDocument>? {
        if (arr == null) return null
        return (0 until arr.length()).map { i ->
            val d = arr.getJSONObject(i)
            ContributedDocument(
                id = d.getString("id"),
                title = d.getString("title"),
                subject = d.getString("subject"),
                examSystem = d.getString("examSystem"),
                examLevel = d.getString("examLevel"),
                description = d.getString("description"),
                contentText = d.getString("contentText"),
                fileName = d.getString("fileName"),
                status = d.getString("status"),
                creditsAwarded = d.getInt("creditsAwarded"),
                createdAtMillis = d.getLong("createdAtMillis")
            )
        }
    }

    private fun serializeMockExams(exams: List<MockExam>): JSONArray = JSONArray().apply {
        exams.forEach { e ->
            put(JSONObject().apply {
                put("id", e.id)
                put("title", e.title)
                put("subject", e.subject)
                put("academicLevel", e.academicLevel)
                put("difficulty", e.difficulty)
                put("durationMinutes", e.durationMinutes)
                put("status", e.status)
                if (e.score != null) put("score", e.score)
                if (e.correctCount != null) put("correctCount", e.correctCount)
                if (e.wrongCount != null) put("wrongCount", e.wrongCount)
                if (e.skippedCount != null) put("skippedCount", e.skippedCount)
                if (e.feedbackSummary != null) put("feedbackSummary", e.feedbackSummary)
                put("createdAtMillis", e.createdAtMillis)
                val ansObj = JSONObject()
                e.answers.forEach { (k, v) -> ansObj.put(k, v) }
                put("answers", ansObj)
                put("questions", JSONArray().apply {
                    e.questions.forEach { q ->
                        put(JSONObject().apply {
                            put("id", q.id)
                            put("position", q.position)
                            put("topic", q.topic)
                            put("questionType", q.questionType)
                            put("prompt", q.prompt)
                            put("correctAnswer", q.correctAnswer)
                            put("explanation", q.explanation)
                            put("points", q.points)
                            put("options", JSONArray().apply {
                                q.options.forEach { opt ->
                                    put(JSONObject().apply {
                                        put("label", opt.label)
                                        put("text", opt.text)
                                    })
                                }
                            })
                        })
                    }
                })
            })
        }
    }

    private fun parseMockExams(arr: JSONArray?): List<MockExam>? {
        if (arr == null) return null
        return (0 until arr.length()).map { i ->
            val e = arr.getJSONObject(i)
            val ansMap = mutableMapOf<String, String>()
            val ansObj = e.optJSONObject("answers")
            if (ansObj != null) {
                ansObj.keys().forEach { k -> ansMap[k] = ansObj.getString(k) }
            }
            val qArr = e.getJSONArray("questions")
            val qs = (0 until qArr.length()).map { j ->
                val q = qArr.getJSONObject(j)
                val optArr = q.getJSONArray("options")
                val opts = (0 until optArr.length()).map { k ->
                    val o = optArr.getJSONObject(k)
                    MockQuestionOption(o.getString("label"), o.getString("text"))
                }
                MockQuestion(
                    id = q.getString("id"),
                    position = q.getInt("position"),
                    topic = q.getString("topic"),
                    questionType = q.getString("questionType"),
                    prompt = q.getString("prompt"),
                    options = opts,
                    correctAnswer = q.getString("correctAnswer"),
                    explanation = q.getString("explanation"),
                    points = q.optInt("points", 1)
                )
            }
            MockExam(
                id = e.getString("id"),
                title = e.getString("title"),
                subject = e.getString("subject"),
                academicLevel = e.getString("academicLevel"),
                difficulty = e.getString("difficulty"),
                durationMinutes = e.getInt("durationMinutes"),
                status = e.getString("status"),
                questions = qs,
                answers = ansMap,
                score = if (e.has("score")) e.getDouble("score") else null,
                correctCount = if (e.has("correctCount")) e.getInt("correctCount") else null,
                wrongCount = if (e.has("wrongCount")) e.getInt("wrongCount") else null,
                skippedCount = if (e.has("skippedCount")) e.getInt("skippedCount") else null,
                feedbackSummary = e.optString("feedbackSummary").takeIf { it.isNotEmpty() },
                createdAtMillis = e.optLong("createdAtMillis", System.currentTimeMillis())
            )
        }
    }

    private fun serializeConversations(convos: List<Conversation>): JSONArray = JSONArray().apply {
        convos.forEach { c ->
            put(JSONObject().apply {
                put("id", c.id)
                put("title", c.title)
                if (c.subject != null) put("subject", c.subject)
                put("updatedAtMillis", c.updatedAtMillis)
                put("messages", JSONArray().apply {
                    c.messages.forEach { m ->
                        put(JSONObject().apply {
                            put("id", m.id)
                            put("role", m.role)
                            put("content", m.content)
                            if (m.attachmentLabel != null) put("attachmentLabel", m.attachmentLabel)
                            put("createdAtMillis", m.createdAtMillis)
                            put("toolsUsed", JSONArray().apply {
                                m.toolsUsed.forEach { t ->
                                    put(JSONObject().apply {
                                        put("name", t.name)
                                        if (t.detail != null) put("detail", t.detail)
                                    })
                                }
                            })
                        })
                    }
                })
            })
        }
    }

    private fun parseConversations(arr: JSONArray?): List<Conversation>? {
        if (arr == null) return null
        return (0 until arr.length()).map { i ->
            val c = arr.getJSONObject(i)
            val mArr = c.getJSONArray("messages")
            val msgs = (0 until mArr.length()).map { j ->
                val m = mArr.getJSONObject(j)
                val tArr = m.optJSONArray("toolsUsed")
                val tools = if (tArr != null) {
                    (0 until tArr.length()).map { k ->
                        val t = tArr.getJSONObject(k)
                        ToolUsage(t.getString("name"), t.optString("detail").takeIf { it.isNotEmpty() })
                    }
                } else emptyList()
                ChatMessage(
                    id = m.getString("id"),
                    role = m.getString("role"),
                    content = m.getString("content"),
                    attachmentLabel = m.optString("attachmentLabel").takeIf { it.isNotEmpty() },
                    toolsUsed = tools,
                    createdAtMillis = m.optLong("createdAtMillis", System.currentTimeMillis())
                )
            }
            Conversation(
                id = c.getString("id"),
                title = c.getString("title"),
                subject = c.optString("subject").takeIf { it.isNotEmpty() },
                messages = msgs,
                updatedAtMillis = c.optLong("updatedAtMillis", System.currentTimeMillis())
            )
        }
    }
}
