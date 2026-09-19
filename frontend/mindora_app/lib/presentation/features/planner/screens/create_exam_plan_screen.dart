import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../providers/planner_providers.dart';

const _commonSubjects = [
  'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Computer Science',
  'Economics', 'English', 'French', 'History', 'Geography',
];

/// Section 31: exam-mode plan creation.
class CreateExamPlanScreen extends ConsumerStatefulWidget {
  const CreateExamPlanScreen({super.key});

  @override
  ConsumerState<CreateExamPlanScreen> createState() => _CreateExamPlanScreenState();
}

class _CreateExamPlanScreenState extends ConsumerState<CreateExamPlanScreen> {
  final _examNameController = TextEditingController();
  final _selectedSubjects = <String>{};
  DateTime? _examDate;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _examNameController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _examNameController.text.trim().isNotEmpty && _selectedSubjects.isNotEmpty && _examDate != null;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final plan = await ref.read(plannerRepositoryProvider).createExamPlan(
            targetExamName: _examNameController.text.trim(),
            subjectNames: _selectedSubjects.toList(),
            examDate: _examDate!,
          );
      ref.read(activePlanIdProvider.notifier).state = plan.id;
      if (mounted) context.go('/planner/summary');
    } catch (error) {
      setState(() => _error = extractApiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Exam plan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              controller: _examNameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Examination (e.g. GCE Advanced Level)'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Subjects', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final subject in _commonSubjects)
                  FilterChip(
                    label: Text(subject),
                    selected: _selectedSubjects.contains(subject),
                    onSelected: (selected) => setState(() {
                      selected ? _selectedSubjects.add(subject) : _selectedSubjects.remove(subject);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(_examDate == null
                  ? 'Pick your exam date'
                  : '${_examDate!.year}-${_examDate!.month.toString().padLeft(2, '0')}-${_examDate!.day.toString().padLeft(2, '0')}'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                  initialDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (picked != null) setState(() => _examDate = picked);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: (_canSubmit && !_isSubmitting) ? _submit : null,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Build my plan'),
            ),
          ],
        ),
      ),
    );
  }
}
