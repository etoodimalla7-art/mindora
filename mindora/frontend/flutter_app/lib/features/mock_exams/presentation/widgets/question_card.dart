import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_colors.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../l10n/app_strings.dart';
import '../../domain/mock_exam_models.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.currentIndex,
    required this.totalCount,
    this.selectedOption,
    this.shortAnswer,
    this.locked = false,
    required this.onOptionSelected,
    required this.onShortAnswerChanged,
  });

  final MockQuestion question;
  final int currentIndex;
  final int totalCount;
  final String? selectedOption;
  final String? shortAnswer;
  final bool locked;
  final void Function(String label) onOptionSelected;
  final void Function(String text) onShortAnswerChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Row(
          children: [
            Text(
              'Question ${currentIndex + 1} / $totalCount',
              style: theme.textTheme.labelMedium,
            ),
            const Spacer(),
            if (locked) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppPalette.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 13,
                      color: AppPalette.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.answerLocked,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppPalette.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${question.points} pt',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          question.prompt,
          style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xxl),

        if (question.questionType == 'mcq' ||
            question.questionType == 'true_false')
          for (final opt in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _OptionTile(
                label: opt.label,
                text: opt.text,
                selected: selectedOption == opt.label,
                enabled: !locked,
                onTap: locked ? null : () => onOptionSelected(opt.label),
              ),
            ),

        if (question.questionType == 'true_false' &&
            question.options.isEmpty)
          for (final label in ['True', 'False'])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _OptionTile(
                label: label[0],
                text: label,
                selected:
                    selectedOption?.toLowerCase() == label.toLowerCase(),
                enabled: !locked,
                onTap: locked
                    ? null
                    : () => onOptionSelected(label.toLowerCase()),
              ),
            ),

        if (question.questionType == 'short_answer')
          _ShortAnswerField(
            key: ValueKey('short_${question.id}'),
            initialText: shortAnswer ?? '',
            enabled: !locked,
            hint: s.isFr
                ? 'Saisissez votre réponse ici...'
                : 'Type your answer here...',
            onChanged: onShortAnswerChanged,
          ),
      ],
    );
  }
}

class _ShortAnswerField extends StatefulWidget {
  const _ShortAnswerField({
    super.key,
    required this.initialText,
    required this.enabled,
    required this.hint,
    required this.onChanged,
  });

  final String initialText;
  final bool enabled;
  final String hint;
  final void Function(String text) onChanged;

  @override
  State<_ShortAnswerField> createState() => _ShortAnswerFieldState();
}

class _ShortAnswerFieldState extends State<_ShortAnswerField> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      enabled: widget.enabled,
      minLines: 3,
      maxLines: 6,
      decoration: InputDecoration(
        hintText: widget.hint,
        alignLabelWithHint: true,
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled || selected ? 1.0 : 0.6,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.10)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.5),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(text, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
