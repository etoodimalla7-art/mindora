import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../domain/dashboard_models.dart';

// ============================================================
// Exam countdown — "Your next examination · 42 days remaining"
// ============================================================

class ExamCountdownCard extends StatelessWidget {
  const ExamCountdownCard({super.key, required this.countdown});
  final ExamCountdown countdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              '${countdown.daysRemaining}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your next examination',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countdown.examName,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${countdown.daysRemaining} days remaining',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Streak — flame icon + count
// ============================================================

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = days > 0;
    return AppSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.14)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.local_fire_department,
              size: 22,
              color: active
                  ? const Color(0xFFF59E0B)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$days ${days == 1 ? 'day' : 'days'}',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  'Study streak',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Today's focus
// ============================================================

class TodayFocusCard extends StatelessWidget {
  const TodayFocusCard({super.key, required this.focus, this.onStart});
  final TodayFocus focus;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.play_arrow_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  focus.title ?? 'Study session',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (focus.durationMinutes != null)
                AppBadge(
                  label: '${focus.durationMinutes} min',
                  tone: AppBadgeTone.primary,
                ),
            ],
          ),
          if (focus.subject != null || focus.topic != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              [
                if (focus.subject != null) focus.subject,
                if (focus.topic != null) focus.topic,
              ].whereType<String>().join(' · '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (focus.objective != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              focus.objective!,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Start session',
            icon: Icons.play_arrow,
            onPressed: onStart ?? () {},
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Readiness ring
// ============================================================

class ReadinessCard extends StatelessWidget {
  const ReadinessCard({
    super.key,
    required this.score,
    required this.breakdown,
  });

  final int score;
  final ReadinessBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exam readiness', style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            'An estimate, not a guarantee',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              AppProgressRing(
                value: score / 100,
                size: 96,
                strokeWidth: 8,
                centerLabel: Text(
                  '$score%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  children: [
                    _ReadinessRow('Knowledge', breakdown.knowledge),
                    _ReadinessRow('Practice', breakdown.practice),
                    _ReadinessRow('Retention', breakdown.retention),
                    _ReadinessRow('Consistency', breakdown.consistency),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow(this.label, this.value);
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Text(
            '$pct%',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Weak topics list
// ============================================================

class WeakTopicsCard extends StatelessWidget {
  const WeakTopicsCard({super.key, required this.topics});
  final List<WeakTopic> topics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_down,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text('Weak topics', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final t in topics) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(t.topic,
                            style: theme.textTheme.bodyMedium),
                      ),
                      Text(
                        '${(t.mastery * 100).round()}%',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.subject,
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: t.mastery,
                      minHeight: 4,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Recent activity
// ============================================================

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key, required this.items});
  final List<RecentActivity> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent activity', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final a in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: theme.textTheme.bodyMedium),
                        if (a.subject != null)
                          Text(a.subject!, style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                  Text(
                    '${a.durationMinutes} min',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
