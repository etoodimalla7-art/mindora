package com.mindora.app.data

import android.content.Context
import com.google.gson.Gson
import com.mindora.app.core.db.OfflineCacheDb
import com.mindora.app.core.network.ApiClient
import com.mindora.app.core.network.ApiModelsMapper
import com.mindora.app.core.network.ChatRequestDto
import com.mindora.app.core.network.CheckoutRequestDto
import com.mindora.app.core.network.ConfirmRequestDto
import com.mindora.app.core.network.CreateMockExamDto
import com.mindora.app.core.network.DeckCreateDto
import com.mindora.app.core.network.EducationUpdateDto
import com.mindora.app.core.network.ExamPlanCreateDto
import com.mindora.app.core.network.FlashcardCreateDto
import com.mindora.app.core.network.GroupMessageCreateDto
import com.mindora.app.core.network.GroupWebSocketClient
import com.mindora.app.core.network.LoginRequestDto
import com.mindora.app.core.network.NotificationPrefUpdateDto
import com.mindora.app.core.network.RefreshRequestDto
import com.mindora.app.core.network.RegisterRequestDto
import com.mindora.app.core.network.ReviewCardRequestDto
import com.mindora.app.core.network.SendOtpRequestDto
import com.mindora.app.core.network.SessionCompleteDto
import com.mindora.app.core.network.SseChatClient
import com.mindora.app.core.network.SseChatEvent
import com.mindora.app.core.network.StudyGroupCreateDto
import com.mindora.app.core.network.SubjectPlanCreateDto
import com.mindora.app.core.network.SubmitAnswerDto
import com.mindora.app.core.network.SubmitDocumentDto
import com.mindora.app.core.network.TicketCreateDto
import com.mindora.app.core.network.TicketRespondDto
import com.mindora.app.core.network.VerifyOtpRequestDto
import com.mindora.app.core.network.VisionAnalyzeRequestDto
import com.mindora.app.core.network.VoiceAnalyzeRequestDto
import com.mindora.app.core.storage.SecureTokenStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import retrofit2.HttpException
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID

data class MindoraState(
    val isAuthenticated: Boolean = false,
    val isLoading: Boolean = false,
    val isOffline: Boolean = false,
    val maintenance: MaintenanceStatus = MaintenanceStatus(),
    val pendingOtpEmail: String? = null,
    val errorMessage: String? = null,
    val infoMessage: String? = null,
    val profile: UserProfile = UserProfile(),
    val themeMode: ThemeModeSetting = ThemeModeSetting.SYSTEM,
    val language: AppLanguage = AppLanguage.EN,
    val streakDays: Int = 0,
    val creditsBalance: Int = 0,
    val dashboardData: DashboardData? = null,
    val topicMasteries: List<TopicMasteryItem> = emptyList(),
    val totalMinutesStudied: Int = 0,
    val sessionsCompleted: Int = 0,
    val mockExamsCompleted: Int = 0,
    val averageExamScore: Double? = null,
    val plans: List<StudyPlan> = emptyList(),
    val conversations: List<Conversation> = emptyList(),
    val activeConversationId: String? = null,
    val aiSending: Boolean = false,
    val decks: List<Deck> = emptyList(),
    val mockExams: List<MockExam> = emptyList(),
    val pastPapers: List<PastPaper> = emptyList(),
    val documents: List<ContributedDocument> = emptyList(),
    val studyGroups: List<StudyGroup> = emptyList(),
    val activeGroupPresence: Int = 1,
    val plansCatalog: List<SubscriptionPlan> = emptyList(),
    val activeSubscription: ActiveSubscription? = null,
    val notifications: List<AppNotification> = emptyList(),
    val notificationPrefs: NotificationPrefs = NotificationPrefs(),
    val tickets: List<SupportTicket> = emptyList(),
    val activeTicket: SupportTicket? = null
) {
    val activeConversation: Conversation?
        get() = conversations.find { it.id == activeConversationId }

    fun buildDashboard(): DashboardData {
        dashboardData?.let { return it }
        val allSessions = plans.flatMap { it.sessions }
        val scheduled = allSessions.filter { !it.isCompleted }.sortedBy { it.scheduledForMillis }
        val completed = allSessions.filter { it.isCompleted }.sortedByDescending { it.scheduledForMillis }
        val activeExamPlan = plans.firstOrNull { it.isActive && it.planType == "exam" }
            ?: plans.firstOrNull { it.isActive }
        val countdown = activeExamPlan?.let {
            ExamCountdown(it.title, it.targetDateMillis, it.daysRemaining)
        }
        val focus = scheduled.firstOrNull()?.let {
            TodayFocus(it.id, it.title, it.subject, it.topic, it.objective, it.durationMinutes)
        }
        val recent = completed.take(4).map {
            RecentActivity(it.id, it.title, it.subject, it.durationMinutes, it.scheduledForMillis)
        }
        return DashboardData(
            streakDays = streakDays,
            examCountdown = countdown,
            todayFocus = focus,
            readinessScore = 0,
            readinessBreakdown = ReadinessBreakdown(),
            weakTopics = emptyList(),
            recentActivity = recent
        )
    }
}

data class VoicePlaybackEvent(
    val text: String,
    val locale: String
)

class MindoraStore(context: Context) {
    private val appContext = context.applicationContext
    private val prefs = appContext.getSharedPreferences("mindora_ui_prefs", Context.MODE_PRIVATE)
    val tokenStore = SecureTokenStore(appContext)
    private val cacheDb = OfflineCacheDb(appContext)
    private val gson = Gson()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val apiClient = ApiClient(tokenStore) {
        scope.launch {
            cacheDb.clearAll()
            _state.update {
                MindoraState(
                    isAuthenticated = false,
                    themeMode = it.themeMode,
                    language = it.language,
                    errorMessage = if (it.language == AppLanguage.FR) {
                        "Session expirée. Veuillez vous reconnecter."
                    } else {
                        "Session expired. Please sign in again."
                    }
                )
            }
        }
    }

    private val sseClient = SseChatClient(apiClient.okHttpClient, tokenStore)
    private val groupWsClient = GroupWebSocketClient(apiClient.okHttpClient, tokenStore)

    private val _state = MutableStateFlow(loadInitialCachedState())
    val state: StateFlow<MindoraState> = _state.asStateFlow()

    private val _voicePlayback = MutableSharedFlow<VoicePlaybackEvent>(extraBufferCapacity = 4)
    val voicePlayback: SharedFlow<VoicePlaybackEvent> = _voicePlayback.asSharedFlow()

    init {
        scope.launch {
            checkMaintenance()
            loadPublicPlans()
            if (tokenStore.hasTokens()) {
                flushPendingOfflineActions()
                refreshAllFromServer()
            }
        }
    }

    private fun loadInitialCachedState(): MindoraState {
        val themeMode = ThemeModeSetting.fromId(prefs.getString("theme_mode", "system"))
        val language = AppLanguage.fromCode(prefs.getString("language", "en"))
        val hasSession = tokenStore.hasTokens()
        if (!hasSession) {
            return MindoraState(
                isAuthenticated = false,
                themeMode = themeMode,
                language = language
            )
        }
        val cached = cacheDb.getObject("full_state", CachedSnapshot::class.java)
        return MindoraState(
            isAuthenticated = true,
            themeMode = themeMode,
            language = cached?.profile?.preferredLanguage ?: language,
            profile = cached?.profile ?: UserProfile(email = tokenStore.userEmail.orEmpty()),
            streakDays = cached?.streakDays ?: 0,
            creditsBalance = cached?.creditsBalance ?: 0,
            dashboardData = cached?.dashboardData,
            plans = cached?.plans ?: emptyList(),
            decks = cached?.decks ?: emptyList(),
            mockExams = cached?.mockExams ?: emptyList(),
            pastPapers = cached?.pastPapers ?: emptyList(),
            documents = cached?.documents ?: emptyList(),
            studyGroups = cached?.studyGroups ?: emptyList(),
            conversations = cached?.conversations ?: emptyList()
        )
    }

    private fun saveCachedSnapshot(s: MindoraState) {
        if (!s.isAuthenticated) return
        val snapshot = CachedSnapshot(
            profile = s.profile,
            streakDays = s.streakDays,
            creditsBalance = s.creditsBalance,
            dashboardData = s.dashboardData,
            plans = s.plans,
            decks = s.decks,
            mockExams = s.mockExams,
            pastPapers = s.pastPapers,
            documents = s.documents,
            studyGroups = s.studyGroups,
            conversations = s.conversations
        )
        cacheDb.putJson("full_state", snapshot)
    }

    private fun updateAndCache(transform: (MindoraState) -> MindoraState) {
        _state.update { current ->
            val next = transform(current)
            saveCachedSnapshot(next)
            next
        }
    }

    fun clearBannerMessages() {
        _state.update { it.copy(errorMessage = null, infoMessage = null) }
    }

    fun getApiBaseUrl(): String = tokenStore.apiBaseUrl

    fun updateApiBaseUrl(url: String) {
        apiClient.updateBaseUrl(url)
        _state.update { it.copy(infoMessage = "API URL updated") }
    }

    fun setThemeMode(mode: ThemeModeSetting) {
        prefs.edit().putString("theme_mode", mode.id).apply()
        _state.update { it.copy(themeMode = mode) }
    }

    fun setLanguage(lang: AppLanguage) {
        prefs.edit().putString("language", lang.code).apply()
        updateAndCache { s ->
            s.copy(
                language = lang,
                profile = s.profile.copy(preferredLanguage = lang)
            )
        }
    }

    // --- Boot / Maintenance / Public Plans ---

    suspend fun checkMaintenance() {
        try {
            val m = apiClient.api.getMaintenance()
            _state.update {
                it.copy(
                    maintenance = MaintenanceStatus(m.enabled, m.message, m.eta),
                    isOffline = false
                )
            }
        } catch (_: Exception) {
        }
    }

    suspend fun loadPublicPlans() {
        try {
            val plans = apiClient.api.listPublicPlans().map { ApiModelsMapper.toSubscriptionPlan(it) }
            _state.update { it.copy(plansCatalog = plans) }
        } catch (_: Exception) {
        }
    }

    // --- Auth & Email OTP & Onboarding ---

    suspend fun signIn(email: String, password: String): Result<Unit> = withContext(Dispatchers.IO) {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        try {
            val resp = apiClient.api.login(LoginRequestDto(email.trim(), password))
            tokenStore.saveSession(
                access = resp.tokens.accessToken,
                refresh = resp.tokens.refreshToken,
                id = resp.user.id,
                email = resp.user.email
            )
            val profile = ApiModelsMapper.toUserProfile(resp.user)
            prefs.edit().putString("language", profile.preferredLanguage.code).apply()
            _state.update {
                it.copy(
                    isAuthenticated = true,
                    isLoading = false,
                    isOffline = false,
                    profile = profile,
                    language = profile.preferredLanguage
                )
            }
            refreshAllFromServer()
            Result.success(Unit)
        } catch (e: Exception) {
            val msg = extractErrorMessage(e)
            _state.update { it.copy(isLoading = false, errorMessage = msg) }
            Result.failure(Exception(msg))
        }
    }

    suspend fun register(fullName: String, email: String, password: String): Result<Unit> =
        withContext(Dispatchers.IO) {
            _state.update { it.copy(isLoading = true, errorMessage = null) }
            try {
                val lang = _state.value.language.code
                val resp = apiClient.api.register(
                    RegisterRequestDto(
                        email = email.trim(),
                        password = password,
                        fullName = fullName.trim(),
                        preferredLanguage = lang,
                        countryCode = "CM"
                    )
                )
                tokenStore.saveSession(
                    access = resp.tokens.accessToken,
                    refresh = resp.tokens.refreshToken,
                    id = resp.user.id,
                    email = resp.user.email
                )
                runCatching {
                    apiClient.api.sendOtp(SendOtpRequestDto(email = email.trim(), purpose = "verify_email"))
                }
                val profile = ApiModelsMapper.toUserProfile(resp.user)
                _state.update {
                    it.copy(
                        isAuthenticated = true,
                        isLoading = false,
                        isOffline = false,
                        pendingOtpEmail = resp.user.email,
                        profile = profile
                    )
                }
                refreshAllFromServer()
                Result.success(Unit)
            } catch (e: Exception) {
                val msg = extractErrorMessage(e)
                _state.update { it.copy(isLoading = false, errorMessage = msg) }
                Result.failure(Exception(msg))
            }
        }

    suspend fun resendOtp(email: String): Result<String> = withContext(Dispatchers.IO) {
        try {
            val resp = apiClient.api.sendOtp(SendOtpRequestDto(email = email.trim(), purpose = "verify_email"))
            _state.update { it.copy(infoMessage = resp.message) }
            Result.success(resp.message)
        } catch (e: Exception) {
            val msg = extractErrorMessage(e)
            _state.update { it.copy(errorMessage = msg) }
            Result.failure(Exception(msg))
        }
    }

    suspend fun verifyOtp(email: String, code: String): Result<Unit> = withContext(Dispatchers.IO) {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        try {
            val resp = apiClient.api.verifyOtp(
                VerifyOtpRequestDto(email = email.trim(), code = code.trim(), purpose = "verify_email")
            )
            updateAndCache { s ->
                s.copy(
                    isLoading = false,
                    pendingOtpEmail = null,
                    infoMessage = resp.message,
                    profile = s.profile.copy(isVerified = resp.isVerified)
                )
            }
            Result.success(Unit)
        } catch (e: Exception) {
            val msg = extractErrorMessage(e)
            _state.update { it.copy(isLoading = false, errorMessage = msg) }
            Result.failure(Exception(msg))
        }
    }

    suspend fun signOut() = withContext(Dispatchers.IO) {
        val refresh = tokenStore.refreshToken
        if (!refresh.isNullOrBlank()) {
            runCatching { apiClient.api.logout(RefreshRequestDto(refresh)) }
        }
        groupWsClient.disconnect()
        tokenStore.clearSession()
        cacheDb.clearAll()
        _state.update {
            MindoraState(
                isAuthenticated = false,
                themeMode = it.themeMode,
                language = it.language,
                plansCatalog = it.plansCatalog
            )
        }
    }

    suspend fun saveEducationProfile(profile: UserProfile): Result<Unit> = withContext(Dispatchers.IO) {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        try {
            val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }
            val targetDateStr = fmt.format(Date(profile.targetExamDateMillis))
            val dto = EducationUpdateDto(
                educationSystem = profile.educationSystem,
                level = profile.level,
                program = profile.program,
                subjects = profile.subjects,
                goals = listOf(profile.goal),
                studyPreferences = mapOf(
                    "study_windows" to profile.studyWindows,
                    "explanation_style" to profile.explanationStyle,
                    "allow_notifications" to profile.allowNotifications
                ),
                targetExamDate = targetDateStr
            )
            val updatedUser = apiClient.api.updateEducation(dto)
            val mapped = ApiModelsMapper.toUserProfile(updatedUser).copy(
                preferredLanguage = profile.preferredLanguage,
                onboardingCompleted = true
            )
            prefs.edit().putString("language", mapped.preferredLanguage.code).apply()
            updateAndCache { s ->
                s.copy(
                    isLoading = false,
                    profile = mapped,
                    language = mapped.preferredLanguage
                )
            }
            refreshAllFromServer()
            Result.success(Unit)
        } catch (e: Exception) {
            val msg = extractErrorMessage(e)
            // Keep onboarding local flags if offline
            updateAndCache { s -> s.copy(isLoading = false, profile = profile, errorMessage = msg) }
            Result.failure(Exception(msg))
        }
    }

    // --- Full Server Sync & Offline Flush ---

    suspend fun refreshAllFromServer() = withContext(Dispatchers.IO) {
        if (!tokenStore.hasTokens()) return@withContext
        _state.update { it.copy(isLoading = true) }
        try {
            coroutineScope {
                val meDef = async { runCatching { apiClient.api.getMe() }.getOrNull() }
                val dashDef = async { runCatching { apiClient.api.getDashboard() }.getOrNull() }
                val progDef = async { runCatching { apiClient.api.getProgressOverview() }.getOrNull() }
                val plansDef = async {
                    runCatching {
                        val list = apiClient.api.listPlans()
                        list.map { p -> runCatching { apiClient.api.getPlan(p.id) }.getOrDefault(p) }
                    }.getOrNull()
                }
                val creditsDef = async { runCatching { apiClient.api.getCreditsBalance() }.getOrNull() }
                val myDocsDef = async { runCatching { apiClient.api.listMyDocuments() }.getOrNull() }
                val libDocsDef = async { runCatching { apiClient.api.listDocumentLibrary() }.getOrNull() }
                val papersDef = async { runCatching { apiClient.api.listPapers() }.getOrNull() }
                val decksDef = async {
                    runCatching {
                        val list = apiClient.api.listDecks()
                        list.map { d ->
                            val cards = runCatching { apiClient.api.getDueCards(d.id, 50) }.getOrDefault(emptyList())
                            ApiModelsMapper.toDeck(d, cards)
                        }
                    }.getOrNull()
                }
                val examsDef = async { runCatching { apiClient.api.listMockExams() }.getOrNull() }
                val convsDef = async { runCatching { apiClient.api.listAiConversations() }.getOrNull() }
                val groupsDef = async { runCatching { apiClient.api.listStudyGroups() }.getOrNull() }
                val plansCatDef = async { runCatching { apiClient.api.listPublicPlans() }.getOrNull() }
                val mySubDef = async { runCatching { apiClient.api.getMySubscription() }.getOrNull() }
                val notifsDef = async { runCatching { apiClient.api.listNotifications() }.getOrNull() }
                val notifPrefsDef = async { runCatching { apiClient.api.getNotificationPrefs() }.getOrNull() }
                val ticketsDef = async { runCatching { apiClient.api.listMyTickets() }.getOrNull() }

                val me = meDef.await()
                val dash = dashDef.await()
                val prog = progDef.await()
                val rawPlans = plansDef.await()
                val credits = creditsDef.await()
                val myDocs = myDocsDef.await()
                val libDocs = libDocsDef.await()
                val papers = papersDef.await()
                val decks = decksDef.await()
                val exams = examsDef.await()
                val convs = convsDef.await()
                val groups = groupsDef.await()
                val catalog = plansCatDef.await()
                val mySub = mySubDef.await()
                val notifs = notifsDef.await()
                val nPrefs = notifPrefsDef.await()
                val tickets = ticketsDef.await()

                val allDocs = ((myDocs ?: emptyList()) + (libDocs ?: emptyList()))
                    .distinctBy { it.id }
                    .map { ApiModelsMapper.toDocument(it) }

                val existingPapersMap = _state.value.pastPapers.associateBy { it.id }
                val mappedPapers = papers?.map { p ->
                    val cachedFile = paperLocalFile(p.fileName)
                    val localPath = if (cachedFile.exists()) cachedFile.absolutePath else existingPapersMap[p.id]?.localFilePath
                    ApiModelsMapper.toPastPaper(p, localPath)
                }

                val mappedGroups = groups?.map { g ->
                    val existingMsgs = _state.value.studyGroups.find { it.id == g.id }?.messages.orEmpty()
                    ApiModelsMapper.toStudyGroup(g, existingMsgs)
                }

                val mappedConvs = convs?.map { c ->
                    val existing = _state.value.conversations.find { it.id == c.id }
                    ApiModelsMapper.toConversation(c, existing?.messages.orEmpty())
                }

                updateAndCache { s ->
                    s.copy(
                        isLoading = false,
                        isOffline = me == null && dash == null,
                        profile = if (me != null) ApiModelsMapper.toUserProfile(me) else s.profile,
                        streakDays = prog?.streakDays ?: dash?.streakDays ?: s.streakDays,
                        creditsBalance = credits?.balance ?: s.creditsBalance,
                        dashboardData = dash?.let { ApiModelsMapper.toDashboardData(it) } ?: s.dashboardData,
                        topicMasteries = prog?.topics?.map { ApiModelsMapper.toTopicMastery(it) } ?: s.topicMasteries,
                        totalMinutesStudied = prog?.totalMinutesStudied ?: s.totalMinutesStudied,
                        sessionsCompleted = prog?.sessionsCompleted ?: s.sessionsCompleted,
                        mockExamsCompleted = prog?.mockExamsCompleted ?: s.mockExamsCompleted,
                        averageExamScore = prog?.averageExamScore ?: s.averageExamScore,
                        plans = rawPlans?.map { ApiModelsMapper.toStudyPlan(it) } ?: s.plans,
                        documents = if (myDocs != null || libDocs != null) allDocs else s.documents,
                        pastPapers = mappedPapers ?: s.pastPapers,
                        decks = decks ?: s.decks,
                        mockExams = exams?.map { ex ->
                            val existing = s.mockExams.find { it.id == ex.id }
                            ApiModelsMapper.toMockExam(ex, existing)
                        } ?: s.mockExams,
                        conversations = mappedConvs ?: s.conversations,
                        studyGroups = mappedGroups ?: s.studyGroups,
                        plansCatalog = catalog?.map { ApiModelsMapper.toSubscriptionPlan(it) } ?: s.plansCatalog,
                        activeSubscription = if (mySub != null || catalog != null) {
                            mySub?.let { ApiModelsMapper.toActiveSubscription(it) }
                        } else s.activeSubscription,
                        notifications = notifs?.map { ApiModelsMapper.toNotification(it) } ?: s.notifications,
                        notificationPrefs = nPrefs?.let { ApiModelsMapper.toNotificationPrefs(it) } ?: s.notificationPrefs,
                        tickets = tickets?.map { ApiModelsMapper.toSupportTicket(it) } ?: s.tickets
                    )
                }
            }
        } catch (_: Exception) {
            _state.update { it.copy(isLoading = false, isOffline = true) }
        }
    }

    private suspend fun flushPendingOfflineActions() {
        val actions = cacheDb.listPendingActions()
        for (act in actions) {
            val ok = try {
                val json = JSONObject(act.payloadJson)
                when (act.actionType) {
                    "complete_session" -> {
                        apiClient.api.completeSession(json.getString("sessionId"), SessionCompleteDto())
                        true
                    }
                    "review_card" -> {
                        apiClient.api.reviewCard(
                            json.getString("cardId"),
                            ReviewCardRequestDto(json.getInt("quality"))
                        )
                        true
                    }
                    else -> true
                }
            } catch (_: IOException) {
                false
            } catch (_: Exception) {
                true
            }
            if (ok) cacheDb.deletePendingAction(act.id)
        }
    }

    // --- Planner & Study Sessions ---

    suspend fun createPlan(
        planType: String,
        title: String,
        subject: String,
        examSystem: String,
        examLevel: String,
        targetDays: Int,
        dailyMinutes: Int
    ): StudyPlan? = withContext(Dispatchers.IO) {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        try {
            val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }
            val targetDate = fmt.format(Date(System.currentTimeMillis() + targetDays.toLong() * 86_400_000L))
            val dto = if (planType == "exam") {
                apiClient.api.createExamPlan(
                    ExamPlanCreateDto(
                        examSystem = examSystem,
                        examLevel = examLevel,
                        examName = title,
                        subjects = listOf(subject),
                        targetDate = targetDate,
                        dailyMinutes = dailyMinutes
                    )
                )
            } else {
                apiClient.api.createSubjectPlan(
                    SubjectPlanCreateDto(
                        subject = subject,
                        topic = title,
                        durationDays = targetDays,
                        dailyMinutes = dailyMinutes
                    )
                )
            }
            val mapped = ApiModelsMapper.toStudyPlan(dto)
            updateAndCache { s ->
                s.copy(isLoading = false, plans = listOf(mapped) + s.plans.filterNot { it.id == mapped.id })
            }
            refreshAllFromServer()
            mapped
        } catch (e: Exception) {
            _state.update { it.copy(isLoading = false, errorMessage = extractErrorMessage(e)) }
            null
        }
    }

    suspend fun startSession(sessionId: String) = withContext(Dispatchers.IO) {
        runCatching { apiClient.api.startSession(sessionId) }
    }

    suspend fun completeSession(sessionId: String) = withContext(Dispatchers.IO) {
        updateAndCache { s ->
            s.copy(
                plans = s.plans.map { p ->
                    p.copy(
                        sessions = p.sessions.map { sess ->
                            if (sess.id == sessionId) sess.copy(status = "completed") else sess
                        }
                    )
                }
            )
        }
        try {
            apiClient.api.completeSession(sessionId, SessionCompleteDto())
            refreshAllFromServer()
        } catch (_: IOException) {
            cacheDb.enqueueAction("complete_session", JSONObject().put("sessionId", sessionId))
            _state.update { it.copy(isOffline = true) }
        } catch (e: Exception) {
            _state.update { it.copy(errorMessage = extractErrorMessage(e)) }
        }
    }

    // --- Flashcards ---

    suspend fun openDeckDueCards(deckId: String) = withContext(Dispatchers.IO) {
        try {
            val cards = apiClient.api.getDueCards(deckId, 50).map { ApiModelsMapper.toFlashcard(it) }
            updateAndCache { s ->
                s.copy(
                    decks = s.decks.map { d ->
                        if (d.id == deckId) d.copy(cards = cards, serverDueCount = cards.size) else d
                    }
                )
            }
        } catch (_: Exception) {
        }
    }

    suspend fun createDeck(title: String, subject: String, description: String) = withContext(Dispatchers.IO) {
        try {
            val created = apiClient.api.createDeck(
                DeckCreateDto(
                    title = title.trim(),
                    description = description.ifBlank { null },
                    subject = subject.ifBlank { null }
                )
            )
            val mapped = ApiModelsMapper.toDeck(created, emptyList())
            updateAndCache { s -> s.copy(decks = listOf(mapped) + s.decks) }
        } catch (e: Exception) {
            _state.update { it.copy(errorMessage = extractErrorMessage(e)) }
        }
    }

    suspend fun addFlashcard(deckId: String, front: String, back: String) = withContext(Dispatchers.IO) {
        try {
            val card = apiClient.api.addCard(deckId, FlashcardCreateDto(front.trim(), back.trim()))
            val mapped = ApiModelsMapper.toFlashcard(card)
            updateAndCache { s ->
                s.copy(
                    decks = s.decks.map { d ->
                        if (d.id == deckId) {
                            d.copy(
                                cards = d.cards + mapped,
                                serverCardCount = (d.serverCardCount ?: d.cards.size) + 1,
                                serverDueCount = (d.serverDueCount ?: d.dueCount) + 1
                            )
                        } else d
                    }
                )
            }
        } catch (e: Exception) {
            _state.update { it.copy(errorMessage = extractErrorMessage(e)) }
        }
    }

    suspend fun generateFlashcardsForDeck(deckId: String, topic: String) = withContext(Dispatchers.IO) {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        try {
            val prompt = "Generate 3 concise flashcards for studying \"$topic\". " +
                "Return ONLY a JSON array of objects with keys \"front\" and \"back\", no markdown."
            val resp = apiClient.api.sendAiChat(ChatRequestDto(message = prompt, subject = topic))
            val raw = resp.message.content.trim()
                .removePrefix("```json")
                .removePrefix("```")
                .removeSuffix("```")
                .trim()
            val arr = runCatching { JSONArray(raw) }.getOrNull()
            val pairs = mutableListOf<Pair<String, String>>()
            if (arr != null && arr.length() > 0) {
                for (i in 0 until arr.length()) {
                    val obj = arr.optJSONObject(i) ?: continue
                    val f = obj.optString("front").trim()
                    val b = obj.optString("back").trim()
                    if (f.isNotEmpty() && b.isNotEmpty()) pairs.add(f to b)
                }
            }
            if (pairs.isEmpty()) {
                pairs.add("Core principle of $topic" to resp.message.content.take(280))
            }
            for ((f, b) in pairs) {
                addFlashcard(deckId, f, b)
            }
            _state.update { it.copy(isLoading = false, infoMessage = "${pairs.size} flashcards added") }
        } catch (e: Exception) {
            _state.update { it.copy(isLoading = false, errorMessage = extractErrorMessage(e)) }
        }
    }

    suspend fun reviewFlashcard(deckId: String, cardId: String, quality: Int) = withContext(Dispatchers.IO) {
        updateAndCache { s ->
            s.copy(
                decks = s.decks.map { deck ->
                    if (deck.id != deckId) deck
                    else {
                        val updatedCards = deck.cards.map { c ->
                            if (c.id == cardId) Sm2Engine.update(c, quality) else c
                        }
                        deck.copy(
                            cards = updatedCards,
                            serverDueCount = (deck.serverDueCount?.minus(1))?.coerceAtLeast(0)
                        )
                    }
                }
            )
        }
        try {
            val res = apiClient.api.reviewCard(cardId, ReviewCardRequestDto(quality))
            val nextMillis = ApiModelsMapper.parseIsoMillis(res.nextReviewAt)
            updateAndCache { s ->
                s.copy(
                    decks = s.decks.map { deck ->
                        if (deck.id != deckId) deck
                        else deck.copy(
                            cards = deck.cards.map { c ->
                                if (c.id == cardId) {
                                    c.copy(
                                        easeFactor = res.easeFactor,
                                        intervalDays = res.intervalDays,
                                        repetitions = res.repetitions,
                                        nextReviewAtMillis = nextMillis
                                    )
                                } else c
                            }
                        )
                    }
                )
            }
        } catch (_: IOException) {
            cacheDb.enqueueAction(
                "review_card",
                JSONObject().put("cardId", cardId).put("quality", quality)
            )
            _state.update { it.copy(isOffline = true) }
        } catch (_: Exception) {
        }
    }

    // --- Mock Exams (Strictly Server-Side Grading) ---

    suspend fun createMockExam(
        title: String,
        subject: String,
        academicLevel: String,
        difficulty: String,
        questionCount: Int,
        durationMinutes: Int
    ): MockExam? = withContext(Dispatchers.IO) {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        try {
            val detail = apiClient.api.createMockExam(
                CreateMockExamDto(
                    title = title.trim(),
                    subject = subject,
                    academicLevel = academicLevel,
                    questionCount = questionCount,
                    durationMinutes = durationMinutes,
                    difficulty = difficulty
                )
            )
            val mapped = ApiModelsMapper.toMockExamDetail(detail)
            updateAndCache { s ->
                s.copy(
                    isLoading = false,
                    mockExams = listOf(mapped) + s.mockExams.filterNot { it.id == mapped.id }
                )
            }
            mapped
        } catch (e: Exception) {
            _state.update { it.copy(isLoading = false, errorMessage = extractErrorMessage(e)) }
            null
        }
    }

    suspend fun loadMockExamDetail(examId: String) = withContext(Dispatchers.IO) {
        try {
            val detail = apiClient.api.getMockExam(examId)
            val mapped = ApiModelsMapper.toMockExamDetail(detail)
            val results = if (detail.status == "graded") {
                runCatching { apiClient.api.getMockExamResults(examId) }.getOrNull()
            } else null

            val merged = if (results != null) ApiModelsMapper.applyResults(mapped, results) else mapped
            updateAndCache { s ->
                s.copy(
                    mockExams = s.mockExams.map { if (it.id == examId) merged else it }
                        .let { list -> if (list.none { it.id == examId }) listOf(merged) + list else list }
                )
            }
        } catch (e: Exception) {
            _state.update { it.copy(errorMessage = extractErrorMessage(e)) }
        }
    }

    suspend fun startMockExam(examId: String) = withContext(Dispatchers.IO) {
        try {
            val detail = apiClient.api.startMockExam(examId)
            val mapped = ApiModelsMapper.toMockExamDetail(detail)
            updateAndCache { s ->
                s.copy(mockExams = s.mockExams.map { if (it.id == examId) mapped.copy(answers = it.answers) else it })
            }
        } catch (_: Exception) {
        }
    }

    suspend fun saveExamAnswer(examId: String, questionId: String, answer: String) {
        updateAndCache { s ->
            s.copy(
                mockExams = s.mockExams.map { e ->
                    if (e.id == examId) e.copy(answers = e.answers + (questionId to answer)) else e
                }
            )
        }
        scope.launch {
            runCatching {
                apiClient.api.submitExamAnswer(examId, SubmitAnswerDto(questionId = questionId, answer = answer))
            }
        }
    }

    suspend fun submitMockExam(examId: String): Result<Unit> = withContext(Dispatchers.IO) {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        try {
            val currentAnswers = _state.value.mockExams.find { it.id == examId }?.answers.orEmpty()
            for ((qId, ans) in currentAnswers) {
                runCatching {
                    apiClient.api.submitExamAnswer(examId, SubmitAnswerDto(questionId = qId, answer = ans))
                }
            }
            val results = apiClient.api.submitMockExam(examId)
            val existing = _state.value.mockExams.find { it.id == examId }
            val graded = if (existing != null) {
                ApiModelsMapper.applyResults(existing, results)
            } else {
                val detail = apiClient.api.getMockExam(examId)
                ApiModelsMapper.applyResults(ApiModelsMapper.toMockExamDetail(detail), results)
            }
            updateAndCache { s ->
                s.copy(
                    isLoading = false,
                    mockExams = s.mockExams.map { if (it.id == examId) graded else it }
                )
            }
            refreshAllFromServer()
            Result.success(Unit)
        } catch (e: Exception) {
            val msg = extractErrorMessage(e)
            _state.update { it.copy(isLoading = false, errorMessage = msg) }
            Result.failure(Exception(msg))
        }
    }

    // --- Past Papers & Documents ---

    private fun paperLocalFile(fileName: String): File {
        val dir = File(appContext.filesDir, "papers")
        if (!dir.exists()) dir.mkdirs()
        return File(dir, fileName.replace(Regex("[^a-zA-Z0-9._-]"), "_"))
    }

    suspend fun downloadPaperPdf(paper: PastPaper): Result<File> = withContext(Dispatchers.IO) {
        val target = paperLocalFile(paper.fileName)
        if (target.exists() && target.length() > 100L) {
            return@withContext Result.success(target)
        }
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        try {
            val body = apiClient.api.downloadPaper(paper.id)
            body.byteStream().use { input ->
                target.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            updateAndCache { s ->
                s.copy(
                    isLoading = false,
                    pastPapers = s.pastPapers.map { p ->
                        if (p.id == paper.id) {
                            p.copy(localFilePath = target.absolutePath, downloadCount = p.downloadCount + 1)
                        } else p
                    }
                )
            }
            Result.success(target)
        } catch (e: Exception) {
            val msg = extractErrorMessage(e)
            _state.update { it.copy(isLoading = false, errorMessage = msg) }
            Result.failure(Exception(msg))
        }
    }

    suspend fun uploadDocument(
        title: String,
        subject: String,
        examSystem: String,
        examLevel: String,
        description: String,
        fileBytes: ByteArray,
        fileName: String,
        mimeType: String
    ): Result<ContributedDocument> = withContext(Dispatchers.IO) {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        try {
            val safeName = fileName.ifBlank { "${title.lowercase().replace(" ", "_")}.txt" }
            val fileReqBody = fileBytes.toRequestBody(mimeType.toMediaTypeOrNull())
            val part = MultipartBody.Part.createFormData("file", safeName, fileReqBody)
            val titleBody = title.trim().toRequestBody("text/plain".toMediaTypeOrNull())
            val descBody = description.ifBlank { title }.trim().toRequestBody("text/plain".toMediaTypeOrNull())

            val uploaded = apiClient.api.uploadDocument(part, titleBody, descBody)
            val finalDoc = runCatching {
                apiClient.api.submitDocumentMetadata(
                    uploaded.id,
                    SubmitDocumentDto(
                        category = subject,
                        academicLevel = examLevel,
                        language = _state.value.language.code,
                        isExamRelated = true,
                        examSystem = examSystem,
                        examName = "$examSystem $examLevel"
                    )
                )
            }.getOrDefault(uploaded)

            val mapped = ApiModelsMapper.toDocument(finalDoc)
            updateAndCache { s ->
                s.copy(
                    isLoading = false,
                    infoMessage = "Document uploaded & queued for indexing",
                    documents = listOf(mapped) + s.documents.filterNot { it.id == mapped.id }
                )
            }
            refreshAllFromServer()
            Result.success(mapped)
        } catch (e: Exception) {
            val msg = extractErrorMessage(e)
            _state.update { it.copy(isLoading = false, errorMessage = msg) }
            Result.failure(Exception(msg))
        }
    }

    // --- AI Tutor (SSE Streaming + Vision + Voice) ---

    fun startNewConversation() {
        _state.update { it.copy(activeConversationId = null) }
    }

    suspend fun selectConversation(id: String) = withContext(Dispatchers.IO) {
        _state.update { it.copy(activeConversationId = id) }
        try {
            val detail = apiClient.api.getAiConversation(id)
            val mapped = ApiModelsMapper.toConversationDetail(detail)
            updateAndCache { s ->
                s.copy(
                    conversations = s.conversations.map { if (it.id == id) mapped else it }
                )
            }
        } catch (_: Exception) {
        }
    }

    suspend fun sendAiMessage(prompt: String, attachmentLabel: String? = null) = withContext(Dispatchers.IO) {
        val cleanPrompt = prompt.trim()
        if (cleanPrompt.isEmpty() && attachmentLabel == null) return@withContext
        val effectivePrompt = if (cleanPrompt.isEmpty()) {
            "Explain this exercise: $attachmentLabel"
        } else if (attachmentLabel != null) {
            "[$attachmentLabel]\n$cleanPrompt"
        } else cleanPrompt

        val userMsgId = "tmp-u-${UUID.randomUUID().toString().take(8)}"
        val assistantMsgId = "tmp-a-${UUID.randomUUID().toString().take(8)}"
        val tempConvId = _state.value.activeConversationId ?: "tmp-c-${UUID.randomUUID().toString().take(8)}"
        val serverConvId = _state.value.activeConversationId?.takeIf { !it.startsWith("tmp-") }

        val userMsg = ChatMessage(id = userMsgId, role = "user", content = effectivePrompt, attachmentLabel = attachmentLabel)
        val assistantPlaceholder = ChatMessage(id = assistantMsgId, role = "assistant", content = "")

        updateAndCache { s ->
            val exists = s.conversations.any { it.id == tempConvId }
            val updatedList = if (!exists) {
                listOf(
                    Conversation(
                        id = tempConvId,
                        title = effectivePrompt.take(40),
                        subject = s.profile.subjects.firstOrNull(),
                        messages = listOf(userMsg, assistantPlaceholder)
                    )
                ) + s.conversations
            } else {
                s.conversations.map { c ->
                    if (c.id == tempConvId) c.copy(messages = c.messages + userMsg + assistantPlaceholder) else c
                }
            }
            s.copy(conversations = updatedList, activeConversationId = tempConvId, aiSending = true, errorMessage = null)
        }

        var activeConvId = tempConvId
        var streamFailed = false

        try {
            sseClient.streamChat(
                ChatRequestDto(
                    message = effectivePrompt,
                    conversationId = serverConvId,
                    subject = _state.value.profile.subjects.firstOrNull()
                )
            ) { ev ->
                when (ev) {
                    is SseChatEvent.Meta -> {
                        val realConvId = ev.conversationId
                        _state.update { s ->
                            val updatedConvs = s.conversations.map { c ->
                                if (c.id == activeConvId) c.copy(id = realConvId) else c
                            }
                            activeConvId = realConvId
                            s.copy(conversations = updatedConvs, activeConversationId = realConvId)
                        }
                    }
                    is SseChatEvent.Token -> {
                        _state.update { s ->
                            s.copy(
                                conversations = s.conversations.map { c ->
                                    if (c.id != activeConvId) c
                                    else c.copy(
                                        messages = c.messages.map { m ->
                                            if (m.id == assistantMsgId) m.copy(content = m.content + ev.text) else m
                                        }
                                    )
                                }
                            )
                        }
                    }
                    is SseChatEvent.Done -> {
                        val realConvId = ev.conversationId ?: activeConvId
                        val tools = ev.toolsUsed.map { ToolUsage(it.first, it.second) }
                        updateAndCache { s ->
                            s.copy(
                                aiSending = false,
                                activeConversationId = realConvId,
                                conversations = s.conversations.map { c ->
                                    if (c.id != activeConvId && c.id != realConvId) c
                                    else c.copy(
                                        id = realConvId,
                                        messages = c.messages.map { m ->
                                            if (m.id == assistantMsgId) {
                                                m.copy(
                                                    id = ev.messageId.ifBlank { assistantMsgId },
                                                    toolsUsed = tools
                                                )
                                            } else m
                                        }
                                    )
                                }
                            )
                        }
                    }
                    is SseChatEvent.Error -> {
                        streamFailed = true
                    }
                }
            }
        } catch (_: Exception) {
            streamFailed = true
        }

        if (streamFailed || _state.value.aiSending) {
            try {
                val fallback = apiClient.api.sendAiChat(
                    ChatRequestDto(
                        message = effectivePrompt,
                        conversationId = serverConvId,
                        subject = _state.value.profile.subjects.firstOrNull()
                    )
                )
                val mappedReply = ApiModelsMapper.toChatMessage(fallback.message)
                updateAndCache { s ->
                    s.copy(
                        aiSending = false,
                        activeConversationId = fallback.conversationId,
                        conversations = s.conversations.map { c ->
                            if (c.id == activeConvId) {
                                c.copy(
                                    id = fallback.conversationId,
                                    messages = c.messages.filterNot { it.id == assistantMsgId } + mappedReply
                                )
                            } else c
                        }
                    )
                }
            } catch (e: Exception) {
                val msg = extractErrorMessage(e)
                updateAndCache { s ->
                    s.copy(
                        aiSending = false,
                        errorMessage = msg,
                        conversations = s.conversations.map { c ->
                            if (c.id == activeConvId) {
                                c.copy(
                                    messages = c.messages.map { m ->
                                        if (m.id == assistantMsgId && m.content.isBlank()) {
                                            m.copy(content = "Connection error: $msg")
                                        } else m
                                    }
                                )
                            } else c
                        }
                    )
                }
            }
        }
    }

    suspend fun sendAiVisionMessage(prompt: String, imageBase64: String, mimeType: String, attachmentName: String) =
        withContext(Dispatchers.IO) {
            val serverConvId = _state.value.activeConversationId?.takeIf { !it.startsWith("tmp-") }
            val userMsg = ChatMessage(
                id = "tmp-u-${UUID.randomUUID().toString().take(8)}",
                role = "user",
                content = prompt.ifBlank { "Analyze this exercise photo" },
                attachmentLabel = attachmentName
            )
            val convKey = serverConvId ?: "tmp-v-${UUID.randomUUID().toString().take(8)}"

            _state.update { s ->
                val exists = s.conversations.any { it.id == convKey }
                val updated = if (!exists) {
                    listOf(Conversation(id = convKey, title = "Photo exercise", messages = listOf(userMsg))) + s.conversations
                } else {
                    s.conversations.map { c -> if (c.id == convKey) c.copy(messages = c.messages + userMsg) else c }
                }
                s.copy(conversations = updated, activeConversationId = convKey, aiSending = true, errorMessage = null)
            }

            try {
                val resp = apiClient.api.sendAiVision(
                    VisionAnalyzeRequestDto(
                        imageBase64 = imageBase64,
                        imageMimeType = mimeType,
                        prompt = prompt,
                        subject = _state.value.profile.subjects.firstOrNull(),
                        conversationId = serverConvId
                    )
                )
                val reply = ApiModelsMapper.toChatMessage(resp.message)
                updateAndCache { s ->
                    s.copy(
                        aiSending = false,
                        activeConversationId = resp.conversationId,
                        conversations = s.conversations.map { c ->
                            if (c.id == convKey) c.copy(id = resp.conversationId, messages = c.messages + reply) else c
                        }
                    )
                }
            } catch (e: Exception) {
                val msg = extractErrorMessage(e)
                _state.update { it.copy(aiSending = false, errorMessage = msg) }
            }
        }

    suspend fun sendAiVoiceTranscript(transcript: String) = withContext(Dispatchers.IO) {
        val clean = transcript.trim()
        if (clean.isEmpty()) return@withContext
        val serverConvId = _state.value.activeConversationId?.takeIf { !it.startsWith("tmp-") }
        val userMsg = ChatMessage(
            id = "tmp-u-${UUID.randomUUID().toString().take(8)}",
            role = "user",
            content = clean,
            attachmentLabel = "Voice"
        )
        val convKey = serverConvId ?: "tmp-voice-${UUID.randomUUID().toString().take(8)}"

        _state.update { s ->
            val exists = s.conversations.any { it.id == convKey }
            val updated = if (!exists) {
                listOf(Conversation(id = convKey, title = clean.take(40), messages = listOf(userMsg))) + s.conversations
            } else {
                s.conversations.map { c -> if (c.id == convKey) c.copy(messages = c.messages + userMsg) else c }
            }
            s.copy(conversations = updated, activeConversationId = convKey, aiSending = true, errorMessage = null)
        }

        try {
            val resp = apiClient.api.sendAiVoice(
                VoiceAnalyzeRequestDto(
                    transcript = clean,
                    language = _state.value.language.code,
                    subject = _state.value.profile.subjects.firstOrNull(),
                    conversationId = serverConvId
                )
            )
            val reply = ApiModelsMapper.toChatMessage(resp.message)
            updateAndCache { s ->
                s.copy(
                    aiSending = false,
                    activeConversationId = resp.conversationId,
                    conversations = s.conversations.map { c ->
                        if (c.id == convKey) c.copy(id = resp.conversationId, messages = c.messages + reply) else c
                    }
                )
            }
            _voicePlayback.tryEmit(VoicePlaybackEvent(resp.ttsText, resp.ttsLocale))
        } catch (e: Exception) {
            _state.update { it.copy(aiSending = false, errorMessage = extractErrorMessage(e)) }
        }
    }

    // --- Study Groups (REST + WebSockets) ---

    suspend fun createStudyGroup(name: String, subject: String, examLevel: String) = withContext(Dispatchers.IO) {
        try {
            val g = apiClient.api.createStudyGroup(
                StudyGroupCreateDto(
                    name = name.trim(),
                    subject = subject.trim().ifBlank { null },
                    examLevel = examLevel.trim().ifBlank { null }
                )
            )
            val mapped = ApiModelsMapper.toStudyGroup(g, emptyList())
            updateAndCache { s -> s.copy(studyGroups = listOf(mapped) + s.studyGroups) }
        } catch (e: Exception) {
            _state.update { it.copy(errorMessage = extractErrorMessage(e)) }
        }
    }

    suspend fun joinStudyGroup(groupId: String) = withContext(Dispatchers.IO) {
        try {
            val g = apiClient.api.joinStudyGroup(groupId)
            updateAndCache { s ->
                s.copy(
                    studyGroups = s.studyGroups.map {
                        if (it.id == groupId) ApiModelsMapper.toStudyGroup(g, it.messages) else it
                    }
                )
            }
        } catch (e: Exception) {
            _state.update { it.copy(errorMessage = extractErrorMessage(e)) }
        }
    }

    suspend fun openStudyGroupChat(groupId: String) = withContext(Dispatchers.IO) {
        val group = _state.value.studyGroups.find { it.id == groupId }
        if (group != null && !group.isMember) {
            runCatching { apiClient.api.joinStudyGroup(groupId) }
        }
        try {
            val msgs = apiClient.api.listGroupMessages(groupId).map {
                ApiModelsMapper.toGroupMessage(it, _state.value.profile.id)
            }
            updateAndCache { s ->
                s.copy(
                    studyGroups = s.studyGroups.map { g ->
                        if (g.id == groupId) g.copy(isMember = true, messages = msgs) else g
                    }
                )
            }
        } catch (_: Exception) {
        }

        groupWsClient.connectStudyGroup(
            groupId = groupId,
            onMessage = { dto ->
                val mapped = ApiModelsMapper.toGroupMessage(dto, _state.value.profile.id)
                updateAndCache { s ->
                    s.copy(
                        studyGroups = s.studyGroups.map { g ->
                            if (g.id == groupId && g.messages.none { it.id == mapped.id }) {
                                g.copy(messages = g.messages + mapped)
                            } else g
                        }
                    )
                }
            },
            onPresence = { count ->
                _state.update { it.copy(activeGroupPresence = count) }
            }
        )
    }

    fun closeStudyGroupChat() {
        groupWsClient.disconnect()
    }

    suspend fun sendGroupMessage(groupId: String, content: String) = withContext(Dispatchers.IO) {
        val trimmed = content.trim()
        if (trimmed.isEmpty()) return@withContext
        val sentViaWs = groupWsClient.sendMessage(trimmed)
        if (!sentViaWs) {
            try {
                val posted = apiClient.api.postGroupMessage(groupId, GroupMessageCreateDto(trimmed))
                val mapped = ApiModelsMapper.toGroupMessage(posted, _state.value.profile.id)
                updateAndCache { s ->
                    s.copy(
                        studyGroups = s.studyGroups.map { g ->
                            if (g.id == groupId && g.messages.none { it.id == mapped.id }) {
                                g.copy(messages = g.messages + mapped)
                            } else g
                        }
                    )
                }
            } catch (e: Exception) {
                _state.update { it.copy(errorMessage = extractErrorMessage(e)) }
            }
        }
    }

    // --- Subscriptions & Flutterwave Checkout ---

    suspend fun startSubscriptionCheckout(planCode: String): Result<Pair<String, String>> =
        withContext(Dispatchers.IO) {
            _state.update { it.copy(isLoading = true, errorMessage = null) }
            try {
                val resp = apiClient.api.startCheckout(CheckoutRequestDto(planCode))
                _state.update { it.copy(isLoading = false) }
                Result.success(resp.checkoutUrl to resp.payment.reference)
            } catch (e: Exception) {
                val msg = extractErrorMessage(e)
                _state.update { it.copy(isLoading = false, errorMessage = msg) }
                Result.failure(Exception(msg))
            }
        }

    suspend fun confirmSubscriptionPayment(reference: String): Result<String> =
        withContext(Dispatchers.IO) {
            _state.update { it.copy(isLoading = true, errorMessage = null) }
            try {
                val res = apiClient.api.confirmPayment(ConfirmRequestDto(reference))
                refreshAllFromServer()
                _state.update { it.copy(isLoading = false, infoMessage = res.message) }
                Result.success(res.message)
            } catch (e: Exception) {
                val msg = extractErrorMessage(e)
                _state.update { it.copy(isLoading = false, errorMessage = msg) }
                Result.failure(Exception(msg))
            }
        }

    suspend fun cancelSubscription() = withContext(Dispatchers.IO) {
        try {
            apiClient.api.cancelSubscription()
            refreshAllFromServer()
            _state.update { it.copy(infoMessage = "Subscription cancelled") }
        } catch (e: Exception) {
            _state.update { it.copy(errorMessage = extractErrorMessage(e)) }
        }
    }

    // --- Notifications & Support ---

    suspend fun markNotificationRead(id: String) = withContext(Dispatchers.IO) {
        runCatching { apiClient.api.markNotificationRead(id) }
        _state.update { s ->
            s.copy(
                notifications = s.notifications.map { n ->
                    if (n.id == id) n.copy(isRead = true) else n
                }
            )
        }
    }

    suspend fun updateNotificationPreferences(prefs: NotificationPrefs) = withContext(Dispatchers.IO) {
        _state.update { it.copy(notificationPrefs = prefs) }
        try {
            val updated = apiClient.api.updateNotificationPrefs(
                NotificationPrefUpdateDto(
                    enabled = prefs.enabled,
                    sessionReminders = prefs.sessionReminders,
                    examCountdown = prefs.examCountdown,
                    streakReminders = prefs.streakReminders
                )
            )
            _state.update { it.copy(notificationPrefs = ApiModelsMapper.toNotificationPrefs(updated)) }
        } catch (e: Exception) {
            _state.update { it.copy(errorMessage = extractErrorMessage(e)) }
        }
    }

    suspend fun createSupportTicket(subject: String, description: String, priority: String) =
        withContext(Dispatchers.IO) {
            try {
                val row = apiClient.api.createTicket(TicketCreateDto(subject.trim(), description.trim(), priority))
                val mapped = ApiModelsMapper.toSupportTicket(row)
                _state.update { s ->
                    s.copy(
                        tickets = listOf(mapped) + s.tickets,
                        infoMessage = "Support ticket created"
                    )
                }
            } catch (e: Exception) {
                _state.update { it.copy(errorMessage = extractErrorMessage(e)) }
            }
        }

    suspend fun openSupportTicket(ticketId: String) = withContext(Dispatchers.IO) {
        try {
            val detail = apiClient.api.getTicketDetail(ticketId)
            val mapped = ApiModelsMapper.toSupportTicketDetail(detail)
            _state.update { it.copy(activeTicket = mapped) }
        } catch (e: Exception) {
            _state.update { it.copy(errorMessage = extractErrorMessage(e)) }
        }
    }

    suspend fun replySupportTicket(ticketId: String, body: String) = withContext(Dispatchers.IO) {
        try {
            apiClient.api.replyTicket(ticketId, TicketRespondDto(body.trim()))
            openSupportTicket(ticketId)
        } catch (e: Exception) {
            _state.update { it.copy(errorMessage = extractErrorMessage(e)) }
        }
    }

    private fun extractErrorMessage(e: Exception): String {
        if (e is HttpException) {
            val body = runCatching { e.response()?.errorBody()?.string() }.getOrNull().orEmpty()
            if (body.isNotBlank()) {
                val parsed = runCatching {
                    val obj = JSONObject(body)
                    obj.optString("detail").takeIf { it.isNotBlank() }
                        ?: obj.optString("message").takeIf { it.isNotBlank() }
                }.getOrNull()
                if (!parsed.isNullOrBlank()) return parsed
            }
            return "Server error (${e.code()})"
        }
        return e.message ?: "Network error"
    }

    private data class CachedSnapshot(
        val profile: UserProfile = UserProfile(),
        val streakDays: Int = 0,
        val creditsBalance: Int = 0,
        val dashboardData: DashboardData? = null,
        val plans: List<StudyPlan> = emptyList(),
        val decks: List<Deck> = emptyList(),
        val mockExams: List<MockExam> = emptyList(),
        val pastPapers: List<PastPaper> = emptyList(),
        val documents: List<ContributedDocument> = emptyList(),
        val studyGroups: List<StudyGroup> = emptyList(),
        val conversations: List<Conversation> = emptyList()
    )
}
