import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// Sections 31/32: exam-mode vs subject-mode, the fork the master spec
/// draws first before either creation flow begins.
class ChoosePlanModeScreen extends StatelessWidget {
  const ChoosePlanModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create a study plan')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ModeCard(
                icon: Icons.flag_rounded,
                title: 'Preparing for an exam',
                subtitle: 'Pick your exam, subjects, and date — we\'ll build the full roadmap.',
                onTap: () => context.push('/planner/create/exam'),
              ),
              const SizedBox(height: AppSpacing.md),
              _ModeCard(
                icon: Icons.menu_book_rounded,
                title: 'Focus on one subject or topic',
                subtitle: 'Pick a subject (and optionally a specific topic) and how long to study it.',
                onTap: () => context.push('/planner/create/subject'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
