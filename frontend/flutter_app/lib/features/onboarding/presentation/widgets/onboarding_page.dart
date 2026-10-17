import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/design/tokens/app_spacing.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.18),
                  primary.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Icon(icon, size: 64, color: primary),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                curve: Curves.easeOutBack,
                duration: 600.ms,
              ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(
                begin: 0.2,
                curve: Curves.easeOut,
                duration: 500.ms,
              ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
        ],
      ),
    );
  }
}
