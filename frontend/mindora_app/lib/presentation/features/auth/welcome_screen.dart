import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/brand_config.dart';
import '../../../core/theme/spacing_tokens.dart';

/// Welcome (section 10, screens 2-3): first thing an unauthenticated
/// user sees. Routes into onboarding (new user) or straight to login.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.auto_awesome_rounded, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Welcome to ${BrandConfig.appName}',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your personal AI tutor, study planner and exam coach — '
                'built for how you actually study.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/onboarding'),
                  child: const Text('Get started'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('I already have an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
