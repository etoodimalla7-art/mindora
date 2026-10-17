import '../../features/documents/presentation/screens/upload_file_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_shell.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_papers_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_document_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_moderation_screen.dart';
import '../../features/ai/presentation/screens/chat_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/documents/presentation/screens/documents_home_screen.dart';
import '../../features/documents/presentation/screens/my_contributions_screen.dart';
import '../../features/documents/presentation/screens/upload_description_screen.dart';
import '../../features/documents/presentation/screens/upload_metadata_screen.dart';
import '../../features/documents/presentation/screens/upload_progress_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/mock_exams/presentation/screens/create_mock_exam_screen.dart';
import '../../features/mock_exams/presentation/screens/mock_exam_results_screen.dart';
import '../../features/mock_exams/presentation/screens/mock_exams_list_screen.dart';
import '../../features/mock_exams/presentation/screens/take_mock_exam_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/planner/presentation/screens/create_exam_plan_screen.dart';
import '../../features/planner/presentation/screens/create_plan_screen.dart';
import '../../features/planner/presentation/screens/plan_detail_screen.dart';
import '../../features/planner/presentation/screens/planner_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/subscription/presentation/screens/checkout_screen.dart';
import '../../features/subscription/presentation/screens/manage_subscription_screen.dart';
import '../../features/subscription/presentation/screens/payment_result_screen.dart';
import '../../features/subscription/presentation/screens/plans_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/styleguide/presentation/styleguide_screen.dart';
import '../../features/debug/presentation/push_debug_screen.dart';
import 'routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.styleguide,
        name: 'styleguide',
        builder: (_, __) => const StyleguideScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.debugPush,
        name: 'debugPush',
        builder: (_, __) => const PushDebugScreen(),
      ),

      // Documents
      GoRoute(
        path: '/documents/upload/file',
        builder: (_, __) => const UploadFileScreen(),
      ),
      GoRoute(
        path: '/documents/upload/metadata',
        builder: (_, state) {
          final file = state.extra as PickedFile;
          return UploadMetadataScreen(file: file);
        },
      ),
      GoRoute(
        path: '/documents/upload/description',
        builder: (_, state) {
          final payload = state.extra as Map<String, dynamic>;
          return UploadDescriptionScreen(payload: payload);
        },
      ),
      GoRoute(
        path: '/documents/progress/:id',
        builder: (_, state) =>
            UploadProgressScreen(documentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/documents/mine',
        builder: (_, __) => const MyContributionsScreen(),
      ),

      // Admin
      // Admin shell (interface séparée)
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.adminDashboard,
            name: 'adminDashboard',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminUsers,
            name: 'adminUsers',
            builder: (_, __) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminPapers,
            name: 'adminPapers',
            builder: (_, __) => const AdminPapersScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/admin/moderation',
        builder: (_, __) => const AdminModerationScreen(),
      ),
      GoRoute(
        path: '/admin/documents/:id',
        builder: (_, state) => AdminDocumentDetailScreen(
          documentId: state.pathParameters['id']!,
        ),
      ),

      GoRoute(
        path: '/mock-exams',
        builder: (_, __) => const MockExamsListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, __) => const CreateMockExamScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) => TakeMockExamScreen(
              examId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: ':id/take',
            builder: (_, state) => TakeMockExamScreen(
              examId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: ':id/results',
            builder: (_, state) => MockExamResultsScreen(
              examId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/subscription/plans',
        builder: (_, __) => const PlansScreen(),
      ),
      GoRoute(
        path: '/subscription/checkout/:planCode',
        builder: (_, state) => CheckoutScreen(
          planCode: state.pathParameters['planCode']!,
        ),
      ),
      GoRoute(
        path: '/subscription/return/:reference',
        builder: (_, state) => PaymentResultScreen(
          reference: state.pathParameters['reference']!,
        ),
      ),
      GoRoute(
        path: '/subscription/manage',
        builder: (_, __) => const ManageSubscriptionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.ai,
            name: 'ai',
            builder: (_, __) => const ChatScreen(),
          ),
          GoRoute(
            path: AppRoutes.planner,
            name: 'planner',
            builder: (_, __) => const PlannerScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreatePlanScreen(),
                routes: [
                  GoRoute(
                    path: 'exam',
                    builder: (_, __) => const CreateExamPlanScreen(),
                  ),
                  GoRoute(
                    path: 'subject',
                    builder: (_, __) => const CreateExamPlanScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: 'plans/:id',
                builder: (_, state) =>
                    PlanDetailScreen(planId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.learn,
            name: 'learn',
            builder: (_, __) => const DocumentsHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 12),
              Text('Page not found\n${state.uri}',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ),
  );
});
