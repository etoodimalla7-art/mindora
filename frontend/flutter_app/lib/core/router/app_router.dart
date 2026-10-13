import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_document_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_moderation_screen.dart';
import '../../features/ai/presentation/screens/chat_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/documents/presentation/screens/documents_home_screen.dart';
import '../../features/documents/presentation/screens/my_contributions_screen.dart';
import '../../features/documents/presentation/screens/upload_description_screen.dart';
import '../../features/documents/presentation/screens/upload_file_screen.dart';
import '../../features/documents/presentation/screens/upload_metadata_screen.dart';
import '../../features/documents/presentation/screens/upload_progress_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/planner/presentation/screens/create_exam_plan_screen.dart';
import '../../features/planner/presentation/screens/create_plan_screen.dart';
import '../../features/planner/presentation/screens/plan_detail_screen.dart';
import '../../features/planner/presentation/screens/planner_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/styleguide/presentation/styleguide_screen.dart';
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

      // Documents
      GoRoute(
        path: '/documents/upload/file',
        builder: (_, __) => const UploadFileScreen(),
      ),
      GoRoute(
        path: '/documents/upload/metadata',
        builder: (_, state) {
          final file = state.extra as PlatformFile;
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
