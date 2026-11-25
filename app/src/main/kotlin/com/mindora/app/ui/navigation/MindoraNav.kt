package com.mindora.app.ui.navigation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.CalendarToday
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.MenuBook
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.mindora.app.R
import com.mindora.app.data.MindoraStore
import com.mindora.app.ui.screens.AiTutorScreen
import com.mindora.app.ui.screens.ContributeDocumentScreen
import com.mindora.app.ui.screens.CreateMockExamScreen
import com.mindora.app.ui.screens.CreatePlanScreen
import com.mindora.app.ui.screens.DocumentsScreen
import com.mindora.app.ui.screens.FlashcardReviewScreen
import com.mindora.app.ui.screens.FlashcardsScreen
import com.mindora.app.ui.screens.HomeScreen
import com.mindora.app.ui.screens.LearnHubScreen
import com.mindora.app.ui.screens.LoginScreen
import com.mindora.app.ui.screens.MaintenanceScreen
import com.mindora.app.ui.screens.MockExamResultsScreen
import com.mindora.app.ui.screens.MockExamsListScreen
import com.mindora.app.ui.screens.NotificationsScreen
import com.mindora.app.ui.screens.OnboardingWizardScreen
import com.mindora.app.ui.screens.PastPapersScreen
import com.mindora.app.ui.screens.PlanDetailScreen
import com.mindora.app.ui.screens.PlannerScreen
import com.mindora.app.ui.screens.ProfileScreen
import com.mindora.app.ui.screens.RegisterScreen
import com.mindora.app.ui.screens.SettingsScreen
import com.mindora.app.ui.screens.StudyGroupChatScreen
import com.mindora.app.ui.screens.StudyGroupsScreen
import com.mindora.app.ui.screens.StudySessionFocusScreen
import com.mindora.app.ui.screens.SubscriptionsScreen
import com.mindora.app.ui.screens.SupportTicketDetailScreen
import com.mindora.app.ui.screens.SupportTicketsScreen
import com.mindora.app.ui.screens.TakeMockExamScreen
import com.mindora.app.ui.screens.VerifyOtpScreen
import com.mindora.app.ui.screens.WelcomeScreen
import com.mindora.app.ui.theme.MindoraPalette
import kotlinx.coroutines.launch

object Routes {
    const val WELCOME = "welcome"
    const val LOGIN = "login"
    const val REGISTER = "register"
    const val VERIFY_OTP = "verify-otp"
    const val ONBOARDING = "onboarding"
    const val HOME = "home"
    const val AI = "ai"
    const val PLANNER = "planner"
    const val LEARN = "learn"
    const val PROFILE = "profile"
    const val PLAN_CREATE = "planner/create"
    const val PLAN_DETAIL = "planner/detail/{planId}"
    const val STUDY_SESSION = "session/{sessionId}"
    const val PAST_PAPERS = "past-papers"
    const val FLASHCARDS = "flashcards"
    const val FLASHCARD_REVIEW = "flashcards/review/{deckId}"
    const val MOCK_EXAMS = "mock-exams"
    const val MOCK_EXAM_CREATE = "mock-exams/create"
    const val MOCK_EXAM_TAKE = "mock-exams/take/{examId}"
    const val MOCK_EXAM_RESULTS = "mock-exams/results/{examId}"
    const val DOCUMENTS = "documents"
    const val CONTRIBUTE_DOC = "documents/contribute"
    const val STUDY_GROUPS = "groups"
    const val STUDY_GROUP_CHAT = "groups/{groupId}"
    const val SUBSCRIPTIONS = "subscriptions"
    const val NOTIFICATIONS = "notifications"
    const val SUPPORT = "support"
    const val SUPPORT_DETAIL = "support/{ticketId}"
    const val SETTINGS = "settings"
}

private data class BottomTab(
    val route: String,
    val labelRes: Int,
    val icon: ImageVector,
    val selectedIcon: ImageVector
)

private val bottomTabs = listOf(
    BottomTab(Routes.HOME, R.string.tab_home, Icons.Outlined.Home, Icons.Filled.Home),
    BottomTab(Routes.AI, R.string.tab_ai, Icons.Outlined.AutoAwesome, Icons.Filled.AutoAwesome),
    BottomTab(Routes.PLANNER, R.string.tab_planner, Icons.Outlined.CalendarToday, Icons.Filled.CalendarToday),
    BottomTab(Routes.LEARN, R.string.tab_learn, Icons.Outlined.MenuBook, Icons.Filled.MenuBook),
    BottomTab(Routes.PROFILE, R.string.tab_profile, Icons.Outlined.Person, Icons.Filled.Person)
)

@Composable
fun MindoraNavHost(store: MindoraStore) {
    val state by store.state.collectAsState()
    val navController = rememberNavController()
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    if (state.maintenance.enabled) {
        MaintenanceScreen(
            maintenance = state.maintenance,
            language = state.language,
            onRetry = { scope.launch { store.checkMaintenance() } }
        )
        return
    }

    val initialDest = remember {
        when {
            !state.isAuthenticated -> Routes.WELCOME
            !state.profile.onboardingCompleted -> Routes.ONBOARDING
            else -> Routes.HOME
        }
    }

    LaunchedEffect(state.errorMessage, state.infoMessage) {
        val msg = state.errorMessage ?: state.infoMessage
        if (!msg.isNullOrBlank()) {
            snackbarHostState.showSnackbar(msg)
            store.clearBannerMessages()
        }
    }

    LaunchedEffect(state.isAuthenticated) {
        if (!state.isAuthenticated && currentRoute != null &&
            currentRoute !in setOf(Routes.WELCOME, Routes.LOGIN, Routes.REGISTER)
        ) {
            navController.navigate(Routes.WELCOME) {
                popUpTo(0) { inclusive = true }
            }
        }
    }

    val showBottomBar = currentRoute in bottomTabs.map { it.route }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    bottomTabs.forEach { tab ->
                        val selected = currentRoute == tab.route
                        val tabLabel = stringResource(tab.labelRes)
                        NavigationBarItem(
                            selected = selected,
                            onClick = {
                                navController.navigate(tab.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon = {
                                Icon(
                                    imageVector = if (selected) tab.selectedIcon else tab.icon,
                                    contentDescription = tabLabel
                                )
                            },
                            label = { Text(tabLabel) }
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        Column(modifier = Modifier.padding(innerPadding)) {
            if (state.isOffline && state.isAuthenticated) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(MindoraPalette.Warning.copy(alpha = 0.16f))
                        .padding(horizontal = 16.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Outlined.CloudOff,
                        contentDescription = null,
                        tint = MindoraPalette.Warning,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = stringResource(R.string.offline_banner),
                        style = MaterialTheme.typography.labelSmall,
                        color = MindoraPalette.Warning
                    )
                }
            }

            NavHost(
                navController = navController,
                startDestination = initialDest,
                modifier = Modifier.weight(1f)
            ) {
                composable(Routes.WELCOME) {
                    WelcomeScreen(
                        language = state.language,
                        onLanguageToggle = { store.setLanguage(it) },
                        onGoToRegister = { navController.navigate(Routes.REGISTER) },
                        onGoToLogin = { navController.navigate(Routes.LOGIN) }
                    )
                }

                composable(Routes.LOGIN) {
                    LoginScreen(
                        language = state.language,
                        loading = state.isLoading,
                        serverError = state.errorMessage,
                        onLogin = { email, password ->
                            store.signIn(email, password).onSuccess {
                                val next = if (store.state.value.profile.onboardingCompleted) Routes.HOME else Routes.ONBOARDING
                                navController.navigate(next) {
                                    popUpTo(0) { inclusive = true }
                                }
                            }
                        },
                        onGoToRegister = { navController.navigate(Routes.REGISTER) },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.REGISTER) {
                    RegisterScreen(
                        language = state.language,
                        loading = state.isLoading,
                        serverError = state.errorMessage,
                        onRegister = { fullName, email, password ->
                            store.register(fullName, email, password).onSuccess {
                                navController.navigate(Routes.VERIFY_OTP) {
                                    popUpTo(Routes.REGISTER) { inclusive = true }
                                }
                            }
                        },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.VERIFY_OTP) {
                    val otpEmail = state.pendingOtpEmail ?: state.profile.email
                    VerifyOtpScreen(
                        email = otpEmail,
                        language = state.language,
                        loading = state.isLoading,
                        errorMessage = state.errorMessage,
                        onVerify = { email, code ->
                            store.verifyOtp(email, code).onSuccess {
                                val next = if (store.state.value.profile.onboardingCompleted) Routes.HOME else Routes.ONBOARDING
                                navController.navigate(next) {
                                    popUpTo(0) { inclusive = true }
                                }
                            }
                        },
                        onResend = { email -> store.resendOtp(email) },
                        onSkip = {
                            val next = if (state.profile.onboardingCompleted) Routes.HOME else Routes.ONBOARDING
                            navController.navigate(next) {
                                popUpTo(0) { inclusive = true }
                            }
                        }
                    )
                }

                composable(Routes.ONBOARDING) {
                    OnboardingWizardScreen(
                        initialProfile = state.profile,
                        onLanguageChanged = { store.setLanguage(it) },
                        onFinish = { updatedProfile ->
                            store.saveEducationProfile(updatedProfile)
                            navController.navigate(Routes.HOME) {
                                popUpTo(0) { inclusive = true }
                            }
                        }
                    )
                }

                composable(Routes.HOME) {
                    HomeScreen(
                        state = state,
                        onRefresh = { store.refreshAllFromServer() },
                        onOpenNotifications = { navController.navigate(Routes.NOTIFICATIONS) },
                        onStartSession = { sessionId -> navController.navigate("session/$sessionId") },
                        onOpenAi = { navController.navigate(Routes.AI) },
                        onOpenMockExams = { navController.navigate(Routes.MOCK_EXAMS) },
                        onOpenFlashcards = { navController.navigate(Routes.FLASHCARDS) },
                        onOpenPlanner = { navController.navigate(Routes.PLANNER) },
                        onOpenPastPapers = { navController.navigate(Routes.PAST_PAPERS) },
                        onOpenStudyGroups = { navController.navigate(Routes.STUDY_GROUPS) }
                    )
                }

                composable(Routes.AI) {
                    AiTutorScreen(
                        language = state.language,
                        conversations = state.conversations,
                        activeConversation = state.activeConversation,
                        sending = state.aiSending,
                        voicePlayback = store.voicePlayback,
                        onSendMessage = { text, att -> store.sendAiMessage(text, att) },
                        onSendVision = { prompt, b64, mime, name -> store.sendAiVisionMessage(prompt, b64, mime, name) },
                        onSendVoiceTranscript = { transcript -> store.sendAiVoiceTranscript(transcript) },
                        onSelectConversation = { id -> store.selectConversation(id) },
                        onNewConversation = { store.startNewConversation() }
                    )
                }

                composable(Routes.PLANNER) {
                    PlannerScreen(
                        language = state.language,
                        plans = state.plans,
                        onOpenPlan = { planId -> navController.navigate("planner/detail/$planId") },
                        onCreatePlan = { navController.navigate(Routes.PLAN_CREATE) }
                    )
                }

                composable(Routes.PLAN_CREATE) {
                    CreatePlanScreen(
                        language = state.language,
                        loading = state.isLoading,
                        errorMessage = state.errorMessage,
                        onCreate = { type, title, subj, sys, lvl, days, mins ->
                            val created = store.createPlan(type, title, subj, sys, lvl, days, mins)
                            if (created != null) {
                                navController.navigate("planner/detail/${created.id}") {
                                    popUpTo(Routes.PLAN_CREATE) { inclusive = true }
                                }
                            }
                        },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(
                    route = Routes.PLAN_DETAIL,
                    arguments = listOf(navArgument("planId") { type = NavType.StringType })
                ) { entry ->
                    val planId = entry.arguments?.getString("planId")
                    val plan = state.plans.find { it.id == planId }
                    PlanDetailScreen(
                        language = state.language,
                        plan = plan,
                        onCompleteSession = { store.completeSession(it) },
                        onStartSession = { sessionId -> navController.navigate("session/$sessionId") },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(
                    route = Routes.STUDY_SESSION,
                    arguments = listOf(navArgument("sessionId") { type = NavType.StringType })
                ) { entry ->
                    val sessionId = entry.arguments?.getString("sessionId")
                    val session = state.plans.flatMap { it.sessions }.find { it.id == sessionId }
                    StudySessionFocusScreen(
                        language = state.language,
                        session = session,
                        onStart = { store.startSession(it) },
                        onComplete = { id ->
                            store.completeSession(id)
                            navController.popBackStack()
                        },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.LEARN) {
                    LearnHubScreen(
                        language = state.language,
                        creditsBalance = state.creditsBalance,
                        papersCount = state.pastPapers.size,
                        decksCount = state.decks.size,
                        examsCount = state.mockExams.size,
                        docsCount = state.documents.size,
                        onOpenPastPapers = { navController.navigate(Routes.PAST_PAPERS) },
                        onOpenFlashcards = { navController.navigate(Routes.FLASHCARDS) },
                        onOpenMockExams = { navController.navigate(Routes.MOCK_EXAMS) },
                        onOpenContribute = { navController.navigate(Routes.CONTRIBUTE_DOC) },
                        onOpenMyContributions = { navController.navigate(Routes.DOCUMENTS) }
                    )
                }

                composable(Routes.PAST_PAPERS) {
                    PastPapersScreen(
                        language = state.language,
                        papers = state.pastPapers,
                        loading = state.isLoading,
                        onDownloadPaper = { store.downloadPaperPdf(it) },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.FLASHCARDS) {
                    FlashcardsScreen(
                        language = state.language,
                        decks = state.decks,
                        loading = state.isLoading,
                        onOpenDeck = { deckId -> navController.navigate("flashcards/review/$deckId") },
                        onCreateDeck = { t, s, d -> store.createDeck(t, s, d) },
                        onAddCard = { id, f, b -> store.addFlashcard(id, f, b) },
                        onGenerateCards = { id, topic -> store.generateFlashcardsForDeck(id, topic) },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(
                    route = Routes.FLASHCARD_REVIEW,
                    arguments = listOf(navArgument("deckId") { type = NavType.StringType })
                ) { entry ->
                    val deckId = entry.arguments?.getString("deckId").orEmpty()
                    val deck = state.decks.find { it.id == deckId }
                    FlashcardReviewScreen(
                        deckId = deckId,
                        deck = deck,
                        language = state.language,
                        onLoadDueCards = { store.openDeckDueCards(it) },
                        onReviewCard = { dId, cId, q -> store.reviewFlashcard(dId, cId, q) },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.MOCK_EXAMS) {
                    MockExamsListScreen(
                        exams = state.mockExams,
                        onCreateExam = { navController.navigate(Routes.MOCK_EXAM_CREATE) },
                        onTakeExam = { examId -> navController.navigate("mock-exams/take/$examId") },
                        onViewResults = { examId -> navController.navigate("mock-exams/results/$examId") },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.MOCK_EXAM_CREATE) {
                    CreateMockExamScreen(
                        loading = state.isLoading,
                        errorMessage = state.errorMessage,
                        onCreate = { t, s, l, d, c, m ->
                            val created = store.createMockExam(t, s, l, d, c, m)
                            if (created != null) {
                                navController.navigate("mock-exams/take/${created.id}") {
                                    popUpTo(Routes.MOCK_EXAM_CREATE) { inclusive = true }
                                }
                            }
                        },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(
                    route = Routes.MOCK_EXAM_TAKE,
                    arguments = listOf(navArgument("examId") { type = NavType.StringType })
                ) { entry ->
                    val examId = entry.arguments?.getString("examId").orEmpty()
                    val exam = state.mockExams.find { it.id == examId }
                    TakeMockExamScreen(
                        examId = examId,
                        exam = exam,
                        loading = state.isLoading,
                        onLoadDetail = { store.loadMockExamDetail(it) },
                        onStartExam = { store.startMockExam(it) },
                        onSelectAnswer = { eId, qId, ans -> store.saveExamAnswer(eId, qId, ans) },
                        onSubmitExam = { eId ->
                            store.submitMockExam(eId).onSuccess {
                                navController.navigate("mock-exams/results/$eId") {
                                    popUpTo("mock-exams/take/$eId") { inclusive = true }
                                }
                            }
                        },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(
                    route = Routes.MOCK_EXAM_RESULTS,
                    arguments = listOf(navArgument("examId") { type = NavType.StringType })
                ) { entry ->
                    val examId = entry.arguments?.getString("examId").orEmpty()
                    val exam = state.mockExams.find { it.id == examId }
                    MockExamResultsScreen(
                        examId = examId,
                        exam = exam,
                        onLoadDetail = { store.loadMockExamDetail(it) },
                        onBackToList = {
                            navController.popBackStack(Routes.MOCK_EXAMS, inclusive = false)
                        },
                        onCreateNew = {
                            navController.navigate(Routes.MOCK_EXAM_CREATE)
                        }
                    )
                }

                composable(Routes.DOCUMENTS) {
                    DocumentsScreen(
                        language = state.language,
                        documents = state.documents,
                        onContributeNew = { navController.navigate(Routes.CONTRIBUTE_DOC) },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.CONTRIBUTE_DOC) {
                    ContributeDocumentScreen(
                        language = state.language,
                        loading = state.isLoading,
                        onSubmit = { t, s, sys, lvl, desc, bytes, name, mime ->
                            store.uploadDocument(t, s, sys, lvl, desc, bytes, name, mime).onSuccess {
                                navController.navigate(Routes.DOCUMENTS) {
                                    popUpTo(Routes.CONTRIBUTE_DOC) { inclusive = true }
                                }
                            }
                        },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.STUDY_GROUPS) {
                    StudyGroupsScreen(
                        language = state.language,
                        groups = state.studyGroups,
                        onCreateGroup = { n, s, l -> store.createStudyGroup(n, s, l) },
                        onJoinGroup = { gId -> store.joinStudyGroup(gId) },
                        onOpenGroup = { gId -> navController.navigate("groups/$gId") },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(
                    route = Routes.STUDY_GROUP_CHAT,
                    arguments = listOf(navArgument("groupId") { type = NavType.StringType })
                ) { entry ->
                    val groupId = entry.arguments?.getString("groupId").orEmpty()
                    val group = state.studyGroups.find { it.id == groupId }
                    StudyGroupChatScreen(
                        groupId = groupId,
                        group = group,
                        presenceCount = state.activeGroupPresence,
                        language = state.language,
                        onOpenGroup = { store.openStudyGroupChat(it) },
                        onCloseGroup = { store.closeStudyGroupChat() },
                        onSendMessage = { gId, content -> store.sendGroupMessage(gId, content) },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.SUBSCRIPTIONS) {
                    SubscriptionsScreen(
                        language = state.language,
                        plans = state.plansCatalog,
                        activeSubscription = state.activeSubscription,
                        loading = state.isLoading,
                        onStartCheckout = { code -> store.startSubscriptionCheckout(code) },
                        onConfirmPayment = { ref -> store.confirmSubscriptionPayment(ref) },
                        onCancelSubscription = { store.cancelSubscription() },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.NOTIFICATIONS) {
                    NotificationsScreen(
                        language = state.language,
                        notifications = state.notifications,
                        prefs = state.notificationPrefs,
                        onMarkRead = { store.markNotificationRead(it) },
                        onUpdatePrefs = { store.updateNotificationPreferences(it) },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.SUPPORT) {
                    SupportTicketsScreen(
                        language = state.language,
                        tickets = state.tickets,
                        onCreateTicket = { subj, desc, prio -> store.createSupportTicket(subj, desc, prio) },
                        onOpenTicket = { id -> navController.navigate("support/$id") },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(
                    route = Routes.SUPPORT_DETAIL,
                    arguments = listOf(navArgument("ticketId") { type = NavType.StringType })
                ) { entry ->
                    val ticketId = entry.arguments?.getString("ticketId").orEmpty()
                    SupportTicketDetailScreen(
                        ticketId = ticketId,
                        ticket = state.activeTicket?.takeIf { it.id == ticketId }
                            ?: state.tickets.find { it.id == ticketId },
                        language = state.language,
                        onLoadTicket = { store.openSupportTicket(it) },
                        onReply = { id, body -> store.replySupportTicket(id, body) },
                        onBack = { navController.popBackStack() }
                    )
                }

                composable(Routes.PROFILE) {
                    ProfileScreen(
                        state = state,
                        onVerifyEmail = {
                            scope.launch {
                                val email = state.profile.email
                                if (email.isNotBlank()) store.resendOtp(email)
                                navController.navigate(Routes.VERIFY_OTP)
                            }
                        },
                        onOpenSubscriptions = { navController.navigate(Routes.SUBSCRIPTIONS) },
                        onOpenNotifications = { navController.navigate(Routes.NOTIFICATIONS) },
                        onOpenSupport = { navController.navigate(Routes.SUPPORT) },
                        onOpenContributions = { navController.navigate(Routes.DOCUMENTS) },
                        onOpenMockExams = { navController.navigate(Routes.MOCK_EXAMS) },
                        onOpenFlashcards = { navController.navigate(Routes.FLASHCARDS) },
                        onOpenStudyGroups = { navController.navigate(Routes.STUDY_GROUPS) },
                        onOpenOnboarding = { navController.navigate(Routes.ONBOARDING) },
                        onOpenSettings = { navController.navigate(Routes.SETTINGS) },
                        onSignOut = {
                            store.signOut()
                            navController.navigate(Routes.WELCOME) {
                                popUpTo(0) { inclusive = true }
                            }
                        }
                    )
                }

                composable(Routes.SETTINGS) {
                    SettingsScreen(
                        themeMode = state.themeMode,
                        language = state.language,
                        apiBaseUrl = store.getApiBaseUrl(),
                        onThemeModeChange = { store.setThemeMode(it) },
                        onLanguageChange = { store.setLanguage(it) },
                        onUpdateApiBaseUrl = { store.updateApiBaseUrl(it) },
                        onSyncNow = { store.refreshAllFromServer() },
                        onBack = { navController.popBackStack() }
                    )
                }
            }
        }
    }
}
