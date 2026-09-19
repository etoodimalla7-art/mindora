import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared_widgets/onboarding_step_scaffold.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../providers/onboarding_controller.dart';
import '../onboarding_screen.dart';

/// Section 11: collect only what's genuinely necessary — program/class
/// and, for exam-bound students, the target exam + date. Optional, so
/// the user can always continue without filling it in.
class AcademicProfileStep extends ConsumerStatefulWidget {
  const AcademicProfileStep({super.key});

  @override
  ConsumerState<AcademicProfileStep> createState() => _AcademicProfileStepState();
}

class _AcademicProfileStepState extends ConsumerState<AcademicProfileStep> {
  final _programController = TextEditingController();
  final _examController = TextEditingController();
  DateTime? _examDate;

  @override
  void dispose() {
    _programController.dispose();
    _examController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = OnboardingStepContext.of(context);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return OnboardingStepScaffold(
      stepIndex: step.stepIndex,
      totalSteps: step.totalSteps,
      onBack: step.onBack,
      title: 'A bit more detail',
      subtitle: 'Optional, but it helps us personalize your plan.',
      onNext: () {
        controller.update((d) => d.copyWith(
              program: _programController.text.trim().isEmpty ? null : _programController.text.trim(),
              targetExam: _examController.text.trim().isEmpty ? null : _examController.text.trim(),
              targetExamDate: _examDate,
            ));
        step.onNext();
      },
      content: ListView(
        children: [
          TextField(
            controller: _programController,
            decoration: const InputDecoration(labelText: 'Program / class (e.g. Computer Engineering, HND 2)'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _examController,
            decoration: const InputDecoration(labelText: 'Target examination (optional)'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(_examDate == null
                ? 'Set exam date (optional)'
                : '${_examDate!.year}-${_examDate!.month.toString().padLeft(2, '0')}-${_examDate!.day.toString().padLeft(2, '0')}'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                initialDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _examDate = picked);
            },
          ),
        ],
      ),
    );
  }
}
