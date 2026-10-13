import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';

class CreatePlanScreen extends StatelessWidget {
  const CreatePlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a plan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              'What are you preparing for?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose a mode. You can create more plans later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                  ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _ModeTile(
              icon: Icons.event_outlined,
              title: 'Exam preparation',
              description:
                  'Prepare for an official examination (GCE, Baccalauréat, HND, BTS...).',
              onTap: () => context.push('/planner/create/exam'),
            ),
            const SizedBox(height: AppSpacing.md),
            _ModeTile(
              icon: Icons.menu_book_outlined,
              title: 'Subject preparation',
              description:
                  'Focus on a specific subject and topic over a set number of days.',
              onTap: () => context.push('/planner/create/subject'),
            ),
            const SizedBox(height: AppSpacing.md),
            _ModeTile(
              icon: Icons.school_outlined,
              title: 'University course',
              description:
                  'Upload your course outline and we will build a plan around it.',
              onTap: () => _comingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('University course mode arrives in Phase 6.')),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
