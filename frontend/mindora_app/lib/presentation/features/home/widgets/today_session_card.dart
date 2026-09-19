import 'package:flutter/material.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../domain/dashboard/study_session.dart';

/// Matches the section 13 mockup: subject, topic, duration, one clear
/// primary action.
class TodaySessionCard extends StatelessWidget {
  const TodaySessionCard({super.key, required this.session, required this.onStart});

  final StudySessionEntity session;
  // Opens the focused study-session interface (section 49, Phase 9+),
  // which is itself responsible for eventually calling "complete".
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = session.status == 'completed';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's focus", style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(session.subjectName, style: theme.textTheme.titleLarge),
            Text(session.topicTitle, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Text('${session.durationMinutes} min', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: isDone
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Completed'),
                    )
                  : ElevatedButton(onPressed: onStart, child: const Text('Start Session')),
            ),
          ],
        ),
      ),
    );
  }
}
