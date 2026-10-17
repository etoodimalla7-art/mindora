import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design/widgets/brand_logo.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/routes.dart';
import '../../auth/data/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    // Minimum display time to let the animation play
    final minimumDelay = Future.delayed(const Duration(milliseconds: 2200));

    // Check if already logged in
    final repo = AuthRepository(ref.read(dioProvider));
    final user = await repo.currentUser();

    await minimumDelay;
    if (!mounted) return;

    if (user != null) {
      if (user.isAdmin) {
        context.go(AppRoutes.adminDashboard);
      } else {
        context.go(AppRoutes.home);
      }
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0A0E1A), const Color(0xFF151B2E)]
                : [
                    theme.colorScheme.primary.withValues(alpha: 0.06),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo animé (scale + fade)
                const BrandLogo(size: 140)
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 32),

                // Wordmark MINDORA
                Text(
                  'MINDORA',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: isDark ? Colors.white : const Color(0xFF0A0E1A),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                const SizedBox(height: 12),

                // Tagline
                Text(
                  AppConfig.appTagline,
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
