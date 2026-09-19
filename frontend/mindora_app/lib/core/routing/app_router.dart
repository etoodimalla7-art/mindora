import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/features/auth/splash_screen.dart';
import '../../presentation/features/auth/welcome_screen.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/auth/register_screen.dart';
import '../../presentation/features/auth/forgot_password_screen.dart';
import '../../presentation/features/onboarding/onboarding_screen.dart';
import '../../presentation/shell/app_shell.dart';
import '../../presentation/features/home/home_screen.dart';
import '../../presentation/features/ai_assistant/ai_assistant_screen.dart';
import '../../presentation/features/planner/planner_screen.dart';
import '../../presentation/features/documents/learn_screen.dart';
import '../../presentation/features/documents/screens/upload_pick_file_screen.dart';
import '../../presentation/features/documents/screens/upload_metadata_screen.dart';
import '../../presentation/features/documents/screens/upload_exam_metadata_screen.dart';
import '../../presentation/features/past_papers/past_papers_screen.dart';
import '../../presentation/features/planner/screens/choose_plan_mode_screen.dart';
import '../../presentation/features/planner/screens/create_exam_plan_screen.dart';
import '../../presentation/features/planner/screens/create_subject_plan_screen.dart';
import '../../presentation/features/planner/screens/plan_summary_screen.dart';
import '../../presentation/features/study_session/study_session_screen.dart';
import '../../domain/dashboard/study_session.dart';
import '../../presentation/features/flashcards/flashcards_screen.dart';
import '../../presentation/features/quizzes/quiz_screen.dart';
import '../../presentation/features/mock_exams/mock_exam_setup_screen.dart';
import '../../presentation/features/progress/readiness_screen.dart';
import '../../presentation/features/notifications/notifications_screen.dart';
import '../../presentation/features/credits/credits_screen.dart';
import '../../presentation/features/admin/review_queue_screen.dart';
import '../../presentation/features/profile/profile_screen.dart';
import '../../presentation/providers/auth_controller.dart';
import '../../presentation/providers/onboarding_controller.dart';

/// A router that reacts to auth state. Built inside a provider so its
/// `refreshListenable` can be driven by Riverpod state changes — no
/// screen ever calls `context.go('/login')` on session expiry; the
/// redirect below handles it centrally.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = GoRouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authStatus = ref.read(authControllerProvider).status;
      final onboardingDone = ref.read(onboardingCompleteProvider).valueOrNull ?? false;
      final path = state.matchedLocation;

      final isAuthRoute = ['/splash', '/welcome', '/login', '/register', '/forgot-password']
          .contains(path);
      final isOnboardingRoute = path == '/onboarding';

      if (authStatus == AuthStatus.unknown) {
        return path == '/splash' ? null : '/splash';
      }
      if (authStatus == AuthStatus.unauthenticated) {
        return isAuthRoute ? null : '/welcome';
      }
      // authenticated:
      if (!onboardingDone && !isOnboardingRoute) return '/onboarding';
      if (onboardingDone && (isAuthRoute || isOnboardingRoute)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(
        path: '/study-session/:id',
        builder: (c, s) => StudySessionScreen(session: s.extra as StudySessionEntity),
      ),
      GoRoute(
        path: '/flashcards',
        builder: (c, s) {
          final args = s.extra as Map<String, dynamic>;
          return FlashcardsScreen(
            topicTitle: args['topicTitle'] as String,
            sourceDocumentId: args['sourceDocumentId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/quiz',
        builder: (c, s) {
          final args = s.extra as Map<String, dynamic>;
          return QuizScreen(
            topicTitle: args['topicTitle'] as String,
            sourceDocumentId: args['sourceDocumentId'] as String?,
            difficulty: args['difficulty'] as String? ?? 'medium',
          );
        },
      ),
      GoRoute(path: '/mock-exam/setup', builder: (c, s) => const MockExamSetupScreen()),
      GoRoute(
        path: '/readiness',
        builder: (c, s) => ReadinessScreen(targetExamName: s.extra as String),
      ),
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: '/credits', builder: (c, s) => const CreditsScreen()),
      GoRoute(path: '/admin/review-queue', builder: (c, s) => const ReviewQueueScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (c, s) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/ai', builder: (c, s) => const AiAssistantScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/planner',
              builder: (c, s) => const PlannerScreen(),
              routes: [
                GoRoute(path: 'create', builder: (c, s) => const ChoosePlanModeScreen()),
                GoRoute(path: 'create/exam', builder: (c, s) => const CreateExamPlanScreen()),
                GoRoute(path: 'create/subject', builder: (c, s) => const CreateSubjectPlanScreen()),
                GoRoute(path: 'summary', builder: (c, s) => const PlanSummaryScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/learn',
              builder: (c, s) => const LearnScreen(),
              routes: [
                GoRoute(path: 'upload', builder: (c, s) => const UploadPickFileScreen()),
                GoRoute(path: 'upload/metadata', builder: (c, s) => const UploadMetadataScreen()),
                GoRoute(path: 'upload/exam-metadata', builder: (c, s) => const UploadExamMetadataScreen()),
                GoRoute(path: 'past-papers', builder: (c, s) => const PastPapersScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod state changes into go_router's Listenable-based
/// refresh mechanism, so auth/onboarding changes trigger a re-evaluation
/// of the redirect logic above.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
    ref.listen(onboardingCompleteProvider, (_, __) => notifyListeners());
  }
}
