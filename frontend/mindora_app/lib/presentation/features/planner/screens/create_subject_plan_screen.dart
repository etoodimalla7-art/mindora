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

/// Section 32: subject-mode plan creation — an optional specific topic
/// makes it a focused revision plan; leaving it blank cycles the
/// subject's full catalog of topics instead.
class CreateSubjectPlanScreen extends ConsumerStatefulWidget {
  const CreateSubjectPlanScreen({super.key});

  @override
  ConsumerState<CreateSubjectPlanScreen> createState() => _CreateSubjectPlanScreenState();
}

class _CreateSubjectPlanScreenState extends ConsumerState<CreateSubjectPlanScreen> {
  final _topicController = TextEditingController();
  final _daysController = TextEditingController(text: '14');
  String? _subject;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _topicController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _subject != null && (int.tryParse(_daysController.text) ?? 0) > 0;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final plan = await ref.read(plannerRepositoryProvider).createSubjectPlan(
            subjectName: _subject!,
            topicTitle: _topicController.text.trim().isEmpty ? null : _topicController.text.trim(),
            durationDays: int.parse(_daysController.text),
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
      appBar: AppBar(title: const Text('Subject plan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            DropdownButtonFormField<String>(
              value: _subject,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: _commonSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _subject = v),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Specific topic (optional)',
                hintText: 'e.g. Differential Equations — leave blank to cover the whole subject',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Duration (days)'),
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
