import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/mock_exam_providers.dart';

const _subjects = [
  'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Computer Science',
  'Economics', 'Accounting', 'English', 'French', 'History', 'Geography',
  'Philosophy',
];

const _levels = [
  'GCE_OL', 'GCE_AL', 'BEPC', 'PROBATOIRE', 'BACCALAUREAT',
  'HND', 'BTS', 'LICENCE', 'MASTER',
];

const _difficulties = ['easy', 'medium', 'hard', 'mixed'];

class CreateMockExamScreen extends ConsumerStatefulWidget {
  const CreateMockExamScreen({super.key});

  @override
  ConsumerState<CreateMockExamScreen> createState() =>
      _CreateMockExamScreenState();
}

class _CreateMockExamScreenState extends ConsumerState<CreateMockExamScreen> {
  final _title = TextEditingController(text: 'Practice exam');
  String _subject = 'Mathematics';
  String? _level = 'GCE_AL';
  String _difficulty = 'medium';
  int _questionCount = 10;
  int _durationMinutes = 30;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().length < 3) {
      _toast('Please enter a title.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final exam = await ref.read(mockExamRepositoryProvider).create(
            title: _title.text.trim(),
            subject: _subject,
            academicLevel: _level,
            questionCount: _questionCount,
            durationMinutes: _durationMinutes,
            difficulty: _difficulty,
          );
      if (!mounted) return;
      ref.invalidate(mockExamsListProvider);
      context.go('/mock-exams/${exam.id}');
    } catch (_) {
      if (!mounted) return;
      _toast(
        'We could not generate questions. Make sure you have at least one '
        'approved document on this subject.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create mock exam')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text('Configure your exam', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'The AI will generate questions from your approved documents.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xxl),

            AppTextField(
              controller: _title,
              label: 'Exam title',
              hint: 'Practice exam',
            ),
            const SizedBox(height: AppSpacing.lg),

            _dropdown('Subject', _subject, _subjects,
                (v) => setState(() => _subject = v)),
            const SizedBox(height: AppSpacing.lg),

            _dropdownOptional('Academic level', _level, _levels,
                (v) => setState(() => _level = v)),
            const SizedBox(height: AppSpacing.lg),

            _dropdown('Difficulty', _difficulty, _difficulties,
                (v) => setState(() => _difficulty = v)),
            const SizedBox(height: AppSpacing.xl),

            Text('Number of questions: $_questionCount',
                style: theme.textTheme.labelLarge),
            Slider(
              value: _questionCount.toDouble(),
              min: 3,
              max: 30,
              divisions: 27,
              label: '$_questionCount',
              onChanged: (v) =>
                  setState(() => _questionCount = v.round()),
            ),

            Text('Duration: $_durationMinutes min',
                style: theme.textTheme.labelLarge),
            Slider(
              value: _durationMinutes.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              label: '$_durationMinutes min',
              onChanged: (v) =>
                  setState(() => _durationMinutes = v.round()),
            ),

            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Generate exam with AI',
              icon: Icons.auto_awesome,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : options.first,
          items: [
            for (final o in options)
              DropdownMenuItem(value: o, child: Text(o.replaceAll('_', ' '))),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _dropdownOptional(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String?>(
          initialValue: options.contains(value) ? value : null,
          items: [
            const DropdownMenuItem(value: null, child: Text('Any')),
            for (final o in options)
              DropdownMenuItem(value: o, child: Text(o.replaceAll('_', ' '))),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
