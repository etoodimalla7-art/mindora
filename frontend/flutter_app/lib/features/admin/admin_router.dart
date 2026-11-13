import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/presentation/auth_controller.dart';
import 'presentation/admin_layout.dart';
import 'presentation/admin_login_screen.dart';
import 'presentation/screens/admin_dashboard_screen.dart';
import 'presentation/screens/admin_document_detail_screen.dart';
import 'presentation/screens/admin_moderation_screen.dart';
import 'presentation/screens/admin_papers_screen.dart';
import 'presentation/screens/admin_users_screen.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state for redirects
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/admin/login',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.session != null;
      final isAdmin = authState.session?.user.isAdmin ?? false;
      final goingToLogin = state.uri.path == '/admin/login';

      if (!isLoggedIn || !isAdmin) {
        return goingToLogin ? null : '/admin/login';
      }
      if (goingToLogin) {
        return '/admin/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/admin/login',
        builder: (_, __) => const AdminLoginScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/papers',
            builder: (_, __) => const AdminPapersScreen(),
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
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/admin/dashboard'),
              child: const Text('Retour au dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
