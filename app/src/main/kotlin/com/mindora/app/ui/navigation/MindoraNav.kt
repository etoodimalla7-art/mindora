package com.mindora.app.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.CalendarToday
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.MenuBook
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
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
import com.mindora.app.ui.screens.MockExamResultsScreen
import com.mindora.app.ui.screens.MockExamsListScreen
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
import com.mindora.app.ui.screens.TakeMockExamScreen
import com.mindora.app.ui.screens.WelcomeScreen
import kotlinx.coroutines.launch

object Routes {
    const val WELCOME = "welcome"
    const val LOGIN = "login"
    const val REGISTER = "register"
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
    const val SETTINGS = "settings"
}

private data class BottomTab(
    val route: String,
    val label: String,
    val icon: ImageVector,
    val selectedIcon: ImageVector
)

private val bottomTabs = listOf(
    BottomTab(Routes.HOME, "Home", Icons.Outlined.Home, Icons.Filled.Home),
    BottomTab(Routes.AI, "AI", Icons.Outlined.AutoAwesome, Icons.Filled.AutoAwesome),
    BottomTab(Routes.PLANNER, "Planner", Icons.Outlined.CalendarToday, Icons.Filled.CalendarToday),
    BottomTab(Routes.LEARN, "Learn", Icons.Outlined.MenuBook, Icons.Filled.MenuBook),
    BottomTab(Routes.PROFILE, "Profile", Icons.Outlined.Person, Icons.Filled.Person)
)

@Composable
fun MindoraNavHost(store: MindoraStore) {
    val state by store.state.collectAsState()
    val navController = rememberNavController()
    val scope = rememberCoroutineScope()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    val startDest = when {
        !state.isAuthenticated -> Routes.WELCOME
        !state.profile.onboardingCompleted -> Routes.WELCOME
        else -> Routes.HOME
    }

    val showBottomBar = currentRoute in bottomTabs.map { it.route }

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    bottomTabs.forEach { tab ->
                        val selected = currentRoute == tab.route
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
                                    contentDescription = tab.label
                                )
                            },
                            label = { Text(tab.label) }
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = startDest,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Routes.WELCOME) {
                WelcomeScreen(
                    language = state.language,
                    onContinueToOnboarding = { navController.navigate(Routes.ONBOARDING) },
                    onQuickEnterHome = {
                        store.updateProfile(state.profile.copy(onboardingCompleted = true))
                        navController.navigate(Routes.HOME) {
                            popUpTo(Routes.WELCOME) { inclusive = true }
                        }
                    },
                    onGoToLogin = { navController.navigate(Routes.LOGIN) }
                )
            }

            composable(Routes.LOGIN) {
                LoginScreen(
                    onLogin = { email ->
                        store.signIn(email)
                        navController.navigate(Routes.HOME) {
                            popUpTo(0) { inclusive = true }
                        }
                    },
                    onGoToRegister = { navController.navigate(Routes.REGISTER) },
                    onBack = { navController.popBackStack() }
                )
            }

            composable(Routes.REGISTER) {
                RegisterScreen(
                    onRegister = { fullName, email ->
                        store.signIn(email, fullName)
                        navController.navigate(Routes.ONBOARDING)
                    },
                    onBack = { navController.popBackStack() }
                )
            }

            composable(Routes.ONBOARDING) {
                OnboardingWizardScreen(
                    initialProfile = state.profile,
                    onLanguageChanged = { store.setLanguage(it) },
                    onFinish = { updatedProfile ->
                        store.updateProfile(updatedProfile)
                        navController.navigate(Routes.HOME) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                )
            }

            composable(Routes.HOME) {
                HomeScreen(
                    state = state,
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
                    conversations = state.conversations,
                    activeConversation = state.activeConversation,
                    sending = state.aiSending,
                    onSendMessage = { text, attachment ->
                        scope.launch { store.sendAiMessage(text, attachment) }
                    },
                    onSelectConversation = { store.selectConversation(it) },
                    onNewConversation = { store.startNewConversation() }
                )
            }

            composable(Routes.PLANNER) {
                PlannerScreen(
                    plans = state.plans,
                    onOpenPlan = { planId -> navController.navigate("planner/detail/$planId") },
                    onCreatePlan = { navController.navigate(Routes.PLAN_CREATE) }
                )
            }

            composable(Routes.PLAN_CREATE) {
                CreatePlanScreen(
                    onCreate = { type, title, subj, sys, lvl, days, mins ->
                        val created = store.createPlan(
                            planType = type,
                            title = title,
                            subject = subj,
                            examSystem = sys,
                            examLevel = lvl,
                            targetDateMillis = System.currentTimeMillis() + days.toLong() * 86_400_000L,
                            dailyMinutes = mins
                        )
                        navController.navigate("planner/detail/${created.id}") {
                            popUpTo(Routes.PLAN_CREATE) { inclusive = true }
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
                    session = session,
                    onComplete = { id ->
                        store.completeSession(id)
                        navController.popBackStack()
                    },
                    onBack = { navController.popBackStack() }
                )
            }

            composable(Routes.LEARN) {
                LearnHubScreen(
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
                    papers = state.pastPapers,
                    creditsBalance = state.creditsBalance,
                    onUnlockPaper = { store.unlockPaper(it) },
                    onBack = { navController.popBackStack() }
                )
            }

            composable(Routes.FLASHCARDS) {
                FlashcardsScreen(
                    decks = state.decks,
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
                val deckId = entry.arguments?.getString("deckId")
                val deck = state.decks.find { it.id == deckId }
                FlashcardReviewScreen(
                    deck = deck,
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
                    onCreate = { t, s, l, d, c, m ->
                        val created = store.createMockExam(t, s, l, d, c, m)
                        navController.navigate("mock-exams/take/${created.id}") {
                            popUpTo(Routes.MOCK_EXAM_CREATE) { inclusive = true }
                        }
                    },
                    onBack = { navController.popBackStack() }
                )
            }

            composable(
                route = Routes.MOCK_EXAM_TAKE,
                arguments = listOf(navArgument("examId") { type = NavType.StringType })
            ) { entry ->
                val examId = entry.arguments?.getString("examId")
                val exam = state.mockExams.find { it.id == examId }
                TakeMockExamScreen(
                    exam = exam,
                    onStartExam = { store.startMockExam(it) },
                    onSelectAnswer = { eId, qId, ans -> store.saveExamAnswer(eId, qId, ans) },
                    onSubmitExam = { eId ->
                        store.submitMockExam(eId)
                        navController.navigate("mock-exams/results/$eId") {
                            popUpTo("mock-exams/take/$eId") { inclusive = true }
                        }
                    },
                    onBack = { navController.popBackStack() }
                )
            }

            composable(
                route = Routes.MOCK_EXAM_RESULTS,
                arguments = listOf(navArgument("examId") { type = NavType.StringType })
            ) { entry ->
                val examId = entry.arguments?.getString("examId")
                val exam = state.mockExams.find { it.id == examId }
                MockExamResultsScreen(
                    exam = exam,
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
                    documents = state.documents,
                    onContributeNew = { navController.navigate(Routes.CONTRIBUTE_DOC) },
                    onBack = { navController.popBackStack() }
                )
            }

            composable(Routes.CONTRIBUTE_DOC) {
                ContributeDocumentScreen(
                    onSubmit = { t, s, sys, lvl, desc, content, file ->
                        store.contributeDocument(t, s, sys, lvl, desc, content, file)
                        navController.navigate(Routes.DOCUMENTS) {
                            popUpTo(Routes.CONTRIBUTE_DOC) { inclusive = true }
                        }
                    },
                    onBack = { navController.popBackStack() }
                )
            }

            composable(Routes.STUDY_GROUPS) {
                StudyGroupsScreen(
                    groups = state.studyGroups,
                    onOpenGroup = { gId -> navController.navigate("groups/$gId") },
                    onBack = { navController.popBackStack() }
                )
            }

            composable(
                route = Routes.STUDY_GROUP_CHAT,
                arguments = listOf(navArgument("groupId") { type = NavType.StringType })
            ) { entry ->
                val groupId = entry.arguments?.getString("groupId")
                val group = state.studyGroups.find { it.id == groupId }
                StudyGroupChatScreen(
                    group = group,
                    onSendMessage = { gId, content -> store.sendGroupMessage(gId, content) },
                    onBack = { navController.popBackStack() }
                )
            }

            composable(Routes.PROFILE) {
                ProfileScreen(
                    state = state,
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
                    onThemeModeChange = { store.setThemeMode(it) },
                    onLanguageChange = { store.setLanguage(it) },
                    onBack = { navController.popBackStack() }
                )
            }
        }
    }
}
