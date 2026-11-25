package com.mindora.app.core.network

import com.mindora.app.data.ActiveSubscription
import com.mindora.app.data.AnswerResult
import com.mindora.app.data.AppLanguage
import com.mindora.app.data.AppNotification
import com.mindora.app.data.ChatMessage
import com.mindora.app.data.ContributedDocument
import com.mindora.app.data.Conversation
import com.mindora.app.data.DashboardData
import com.mindora.app.data.Deck
import com.mindora.app.data.ExamCountdown
import com.mindora.app.data.Flashcard
import com.mindora.app.data.GroupMessage
import com.mindora.app.data.MockExam
import com.mindora.app.data.MockQuestion
import com.mindora.app.data.MockQuestionOption
import com.mindora.app.data.NotificationPrefs
import com.mindora.app.data.PastPaper
import com.mindora.app.data.ReadinessBreakdown
import com.mindora.app.data.RecentActivity
import com.mindora.app.data.StudyGroup
import com.mindora.app.data.StudyPlan
import com.mindora.app.data.StudySession
import com.mindora.app.data.SubscriptionPlan
import com.mindora.app.data.SupportMessage
import com.mindora.app.data.SupportTicket
import com.mindora.app.data.TodayFocus
import com.mindora.app.data.ToolUsage
import com.mindora.app.data.TopicMasteryItem
import com.mindora.app.data.TopicStat
import com.mindora.app.data.UserProfile
import com.mindora.app.data.WeakTopic
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

object ApiModelsMapper {

    fun parseIsoMillis(raw: String?): Long {
        if (raw.isNullOrBlank()) return System.currentTimeMillis()
        val trimmed = raw.trim()
        val patterns = listOf(
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
            "yyyy-MM-dd'T'HH:mm:ssXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        )
        for (p in patterns) {
            try {
                val fmt = SimpleDateFormat(p, Locale.US).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }
                val d = fmt.parse(trimmed)
                if (d != null) return d.time
            } catch (_: Exception) {
            }
        }
        return System.currentTimeMillis()
    }

    fun toUserProfile(dto: UserOutDto): UserProfile {
        val edu = dto.educationProfile
        val prefs = edu?.studyPreferences ?: emptyMap()
        val windows = (prefs["study_windows"] as? List<*>)?.mapNotNull { it?.toString() }
            ?: listOf("evening")
        val style = prefs["explanation_style"]?.toString() ?: "standard"
        val allowNotifs = (prefs["allow_notifications"] as? Boolean) ?: true
        val hasOnboarding = edu != null && (!edu.educationSystem.isNullOrBlank() || edu.subjects.isNotEmpty())

        return UserProfile(
            id = dto.id,
            fullName = dto.fullName ?: dto.email.substringBefore("@"),
            email = dto.email,
            isVerified = dto.isVerified,
            preferredLanguage = AppLanguage.fromCode(dto.preferredLanguage),
            countryCode = dto.countryCode,
            educationSystem = edu?.educationSystem ?: "Anglophone",
            level = edu?.level ?: "GCE Advanced Level",
            program = edu?.program ?: "Science",
            subjects = edu?.subjects?.ifEmpty { listOf("Mathematics") } ?: listOf("Mathematics"),
            goal = edu?.goals?.firstOrNull() ?: "pass_exam",
            targetExamDateMillis = parseIsoMillis(edu?.targetExamDate),
            studyWindows = windows,
            explanationStyle = style,
            allowNotifications = allowNotifs,
            onboardingCompleted = hasOnboarding
        )
    }

    fun toDashboardData(dto: DashboardResponseDto): DashboardData {
        return DashboardData(
            streakDays = dto.streakDays,
            examCountdown = dto.examCountdown?.let {
                ExamCountdown(
                    examName = it.examName,
                    targetDateMillis = parseIsoMillis(it.targetDate),
                    daysRemaining = it.daysRemaining
                )
            },
            todayFocus = dto.todayFocus?.takeIf { !it.sessionId.isNullOrBlank() && !it.title.isNullOrBlank() }?.let {
                TodayFocus(
                    sessionId = it.sessionId!!,
                    title = it.title!!,
                    subject = it.subject.orEmpty(),
                    topic = it.topic.orEmpty(),
                    objective = it.objective.orEmpty(),
                    durationMinutes = it.durationMinutes ?: 30
                )
            },
            readinessScore = dto.readinessScore,
            readinessBreakdown = ReadinessBreakdown(
                knowledge = dto.readinessBreakdown.knowledge,
                practice = dto.readinessBreakdown.practice,
                retention = dto.readinessBreakdown.retention,
                consistency = dto.readinessBreakdown.consistency
            ),
            weakTopics = dto.weakTopics.map { WeakTopic(it.subject, it.topic, it.mastery) },
            recentActivity = dto.recentActivity.map {
                RecentActivity(
                    sessionId = it.sessionId,
                    title = it.title,
                    subject = it.subject.orEmpty(),
                    durationMinutes = it.durationMinutes,
                    completedAtMillis = parseIsoMillis(it.completedAt)
                )
            }
        )
    }

    fun toTopicMastery(dto: TopicMasteryDto): TopicMasteryItem = TopicMasteryItem(
        subject = dto.subject,
        topic = dto.topic,
        mastery = dto.mastery,
        questionsSeen = dto.questionsSeen,
        questionsCorrect = dto.questionsCorrect,
        minutesStudied = dto.minutesStudied
    )

    fun toStudySession(dto: StudySessionOutDto): StudySession = StudySession(
        id = dto.id,
        planId = dto.planId.orEmpty(),
        title = dto.title,
        subject = dto.subject.orEmpty(),
        topic = dto.topic.orEmpty(),
        objective = dto.objective.orEmpty(),
        scheduledForMillis = parseIsoMillis(dto.scheduledFor),
        durationMinutes = dto.durationMinutes,
        status = dto.status
    )

    fun toStudyPlan(dto: StudyPlanOutDto): StudyPlan = StudyPlan(
        id = dto.id,
        planType = dto.planType,
        title = dto.title,
        subject = dto.subject ?: dto.examName ?: "General",
        examSystem = dto.examSystem.orEmpty(),
        examLevel = dto.examLevel.orEmpty(),
        targetDateMillis = parseIsoMillis(dto.targetDate),
        dailyMinutes = dto.dailyMinutes,
        isActive = dto.isActive,
        sessions = dto.sessions.map { toStudySession(it) }
    )

    fun toDocument(dto: DocumentOutDto): ContributedDocument = ContributedDocument(
        id = dto.id,
        title = dto.title,
        subject = dto.category ?: "General",
        examSystem = dto.examSystem ?: "GCE",
        examLevel = dto.academicLevel ?: "",
        description = dto.description,
        contentText = "",
        fileName = dto.originalFilename,
        status = dto.status,
        creditsAwarded = if (dto.status == "approved") 5 else 0,
        createdAtMillis = parseIsoMillis(dto.createdAt)
    )

    fun toPastPaper(dto: PaperRowDto, localFilePath: String?): PastPaper {
        val mb = dto.fileSize / (1024.0 * 1024.0)
        val sizeLabel = if (mb >= 1.0) String.format(Locale.US, "%.1f MB", mb)
        else "${(dto.fileSize / 1024L).coerceAtLeast(1)} KB"
        return PastPaper(
            id = dto.id,
            title = dto.title,
            subject = dto.subject,
            examSystem = dto.examSystem,
            examLevel = dto.examLevel,
            examYear = dto.examYear ?: 2024,
            session = "Official",
            language = dto.language,
            fileName = dto.fileName,
            fileSizeLabel = sizeLabel,
            downloadCount = dto.downloadCount,
            localFilePath = localFilePath
        )
    }

    fun toFlashcard(dto: FlashcardOutDto): Flashcard = Flashcard(
        id = dto.id,
        deckId = dto.deckId,
        front = dto.front,
        back = dto.back,
        easeFactor = dto.easeFactor,
        intervalDays = dto.intervalDays,
        repetitions = dto.repetitions,
        nextReviewAtMillis = if (dto.nextReviewAt == null) System.currentTimeMillis() - 1000L
        else parseIsoMillis(dto.nextReviewAt)
    )

    fun toDeck(dto: DeckOutDto, cards: List<FlashcardOutDto>): Deck = Deck(
        id = dto.id,
        title = dto.title,
        subject = dto.subject ?: "General",
        description = dto.description.orEmpty(),
        cards = cards.map { toFlashcard(it) },
        serverCardCount = dto.cardCount,
        serverDueCount = dto.dueCount
    )

    fun toMockQuestion(dto: MockQuestionOutDto): MockQuestion = MockQuestion(
        id = dto.id,
        position = dto.position,
        topic = dto.difficulty,
        questionType = dto.questionType,
        prompt = dto.prompt,
        options = dto.options.map { MockQuestionOption(it.label, it.text) },
        correctAnswer = null,
        explanation = null,
        points = dto.points
    )

    fun toMockExam(dto: MockExamOutDto, existing: MockExam?): MockExam = MockExam(
        id = dto.id,
        title = dto.title,
        subject = dto.subject,
        academicLevel = dto.academicLevel.orEmpty(),
        difficulty = dto.difficulty,
        durationMinutes = dto.durationMinutes,
        status = dto.status,
        serverQuestionCount = dto.questionCount,
        questions = existing?.questions.orEmpty(),
        answers = existing?.answers.orEmpty(),
        answerResults = existing?.answerResults.orEmpty(),
        topicBreakdown = existing?.topicBreakdown.orEmpty(),
        score = dto.score,
        correctCount = dto.correctCount,
        wrongCount = dto.wrongCount,
        skippedCount = dto.skippedCount,
        feedbackSummary = existing?.feedbackSummary,
        createdAtMillis = parseIsoMillis(dto.createdAt)
    )

    fun toMockExamDetail(dto: MockExamDetailDto): MockExam = MockExam(
        id = dto.id,
        title = dto.title,
        subject = dto.subject,
        academicLevel = dto.academicLevel.orEmpty(),
        difficulty = dto.difficulty,
        durationMinutes = dto.durationMinutes,
        status = dto.status,
        serverQuestionCount = dto.questionCount,
        questions = dto.questions.map { toMockQuestion(it) },
        score = dto.score,
        correctCount = dto.correctCount,
        wrongCount = dto.wrongCount,
        skippedCount = dto.skippedCount,
        createdAtMillis = parseIsoMillis(dto.createdAt)
    )

    fun applyResults(exam: MockExam, results: MockExamResultsDto): MockExam {
        val mappedAnswers = results.answers.map { a ->
            AnswerResult(
                questionId = a.questionId,
                userAnswer = a.userAnswer,
                isCorrect = a.isCorrect == true,
                correctAnswer = a.correctAnswer,
                explanation = a.explanation ?: a.aiFeedback
            )
        }
        val breakdown = results.topicBreakdown.mapValues { (_, counts) ->
            TopicStat(
                total = counts["total"] ?: 0,
                correct = counts["correct"] ?: 0
            )
        }
        val answersMap = results.answers
            .filter { !it.userAnswer.isNullOrBlank() }
            .associate { it.questionId to it.userAnswer!! }
        val resultByQ = mappedAnswers.associateBy { it.questionId }
        val enrichedQuestions = exam.questions.map { q ->
            val r = resultByQ[q.id]
            if (r != null) q.copy(correctAnswer = r.correctAnswer, explanation = r.explanation) else q
        }
        return exam.copy(
            status = results.status,
            score = results.score,
            correctCount = results.correctCount,
            wrongCount = results.wrongCount,
            skippedCount = results.skippedCount,
            feedbackSummary = results.feedbackSummary,
            answerResults = mappedAnswers,
            topicBreakdown = breakdown,
            answers = exam.answers + answersMap,
            questions = enrichedQuestions
        )
    }

    fun toChatMessage(dto: MessageOutDto): ChatMessage {
        val tools = dto.toolsUsed.mapNotNull { m ->
            val name = m["name"]?.toString()?.takeIf { it.isNotBlank() } ?: return@mapNotNull null
            val detail = m["result_preview"]?.toString()?.takeIf { it.isNotBlank() }
            ToolUsage(name, detail)
        }
        return ChatMessage(
            id = dto.id,
            role = dto.role,
            content = dto.content,
            toolsUsed = tools,
            createdAtMillis = parseIsoMillis(dto.createdAt)
        )
    }

    fun toConversation(dto: ConversationOutDto, existingMessages: List<ChatMessage>): Conversation =
        Conversation(
            id = dto.id,
            title = dto.title,
            subject = dto.subject,
            messages = existingMessages,
            updatedAtMillis = parseIsoMillis(dto.updatedAt)
        )

    fun toConversationDetail(dto: ConversationDetailDto): Conversation = Conversation(
        id = dto.id,
        title = dto.title,
        subject = dto.subject,
        messages = dto.messages.map { toChatMessage(it) },
        updatedAtMillis = parseIsoMillis(dto.updatedAt)
    )

    fun toStudyGroup(dto: StudyGroupOutDto, messages: List<GroupMessage>): StudyGroup = StudyGroup(
        id = dto.id,
        name = dto.name,
        subject = dto.subject ?: "General",
        examLevel = dto.examLevel ?: dto.examSystem ?: "",
        memberCount = dto.memberCount,
        isMember = dto.isMember,
        messages = messages
    )

    fun toGroupMessage(dto: GroupMessageOutDto, myUserId: String): GroupMessage = GroupMessage(
        id = dto.id,
        senderName = dto.userName ?: "Student",
        content = dto.content,
        isMe = dto.userId == myUserId && myUserId.isNotBlank(),
        sentAtMillis = parseIsoMillis(dto.createdAt)
    )

    fun toSubscriptionPlan(dto: PlanOutDto): SubscriptionPlan {
        val featList = dto.features.entries.map { (k, v) ->
            when (v) {
                is Boolean -> if (v) k.replace('_', ' ') else ""
                else -> "${k.replace('_', ' ')}: $v"
            }
        }.filter { it.isNotBlank() }
        return SubscriptionPlan(
            id = dto.id,
            code = dto.code,
            name = dto.name,
            description = dto.description.orEmpty(),
            tier = dto.tier,
            amountMinor = dto.amountMinor,
            currency = dto.currency,
            billingCycle = dto.billingCycle,
            features = featList
        )
    }

    fun toActiveSubscription(dto: SubscriptionDetailDto): ActiveSubscription = ActiveSubscription(
        id = dto.id,
        status = dto.status,
        planName = dto.plan?.name ?: "Pro",
        tier = dto.plan?.tier ?: "pro",
        periodEnd = dto.currentPeriodEnd
    )

    fun toNotification(dto: NotificationOutDto): AppNotification = AppNotification(
        id = dto.id,
        type = dto.type,
        title = dto.title,
        body = dto.body,
        isRead = !dto.readAt.isNullOrBlank(),
        createdAt = dto.createdAt
    )

    fun toNotificationPrefs(dto: NotificationPrefOutDto): NotificationPrefs = NotificationPrefs(
        enabled = dto.enabled,
        sessionReminders = dto.sessionReminders,
        examCountdown = dto.examCountdown,
        streakReminders = dto.streakReminders
    )

    fun toSupportTicket(dto: TicketRowDto): SupportTicket = SupportTicket(
        id = dto.id,
        subject = dto.subject,
        description = dto.description,
        status = dto.status,
        priority = dto.priority,
        createdAt = dto.createdAt
    )

    fun toSupportTicketDetail(dto: TicketDetailDto): SupportTicket = SupportTicket(
        id = dto.id,
        subject = dto.subject,
        description = dto.description,
        status = dto.status,
        priority = dto.priority,
        createdAt = dto.createdAt,
        messages = dto.messages.map {
            SupportMessage(
                id = it.id,
                authorEmail = it.authorEmail,
                body = it.body,
                isAdmin = it.isAdmin,
                createdAt = it.createdAt
            )
        }
    )
}
