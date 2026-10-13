import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
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
            builder: (_, __) => const _Placeholder(title: 'AI Assistant'),
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
            builder: (_, __) => const _Placeholder(title: 'Learn'),
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

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\ncoming online soon.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
