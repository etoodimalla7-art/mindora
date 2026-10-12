import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design/widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$greeting 👋',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          )),
                      const SizedBox(height: 4),
                      Text('Welcome to ${AppConfig.appName}',
                          style: theme.textTheme.headlineSmall),
                    ],
                  ),
                ),
                const AppAvatar(initials: 'MD'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSurface(
              padding: const EdgeInsets.all(AppSpacing.xl),
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Get started',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tell us your exam and subjects. We will build a personalized study plan.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Create my study plan',
                    icon: Icons.auto_awesome,
                    onPressed: () {},
                    expand: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text("Today's focus", style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            const AppEmptyState(
              icon: Icons.event_available_outlined,
              title: 'Nothing scheduled yet',
              message:
                  'Once you create a study plan, your daily sessions will appear here.',
            ),
          ],
        ),
      ),
    );
  }
}
