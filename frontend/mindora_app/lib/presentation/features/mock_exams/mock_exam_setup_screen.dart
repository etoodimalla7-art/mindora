import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../providers/mock_exams_providers.dart';
import 'mock_exam_taking_screen.dart';

const _commonSubjects = [
  'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Computer Science',
  'Economics', 'English', 'French', 'History', 'Geography',
];

/// Section 40: configure a timed, multi-subject mock exam before
/// generating it.
class MockExamSetupScreen extends ConsumerStatefulWidget {
  const MockExamSetupScreen({super.key});

  @override
  ConsumerState<MockExamSetupScreen> createState() => _MockExamSetupScreenState();
}

class _MockExamSetupScreenState extends ConsumerState<MockExamSetupScreen> {
  final _selectedSubjects = <String>{};
  int _questionsPerSubject = 5;
  int _durationMinutes = 60;
  String _difficulty = 'medium';
  bool _isCreating = false;
  String? _error;

  Future<void> _create() async {
    if (_selectedSubjects.isEmpty) return;
    setState(() {
      _isCreating = true;
      _error = null;
    });
    try {
      final exam = await ref.read(mockExamsRepositoryProvider).create(
            subjectNames: _selectedSubjects.toList(),
            numQuestionsPerSubject: _questionsPerSubject,
            difficulty: _difficulty,
            durationMinutes: _durationMinutes,
          );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MockExamTakingScreen(exam: exam)),
        );
      }
    } catch (error) {
      setState(() => _error = extractApiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mock Exam')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
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
            Text('Questions per subject: $_questionsPerSubject', style: theme.textTheme.titleLarge),
            Slider(
              value: _questionsPerSubject.toDouble(), min: 3, max: 15, divisions: 12,
              label: '$_questionsPerSubject',
              onChanged: (v) => setState(() => _questionsPerSubject = v.round()),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Duration: $_durationMinutes minutes', style: theme.textTheme.titleLarge),
            Slider(
              value: _durationMinutes.toDouble(), min: 15, max: 180, divisions: 11,
              label: '$_durationMinutes min',
              onChanged: (v) => setState(() => _durationMinutes = v.round()),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(labelText: 'Difficulty'),
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('Easy')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'hard', child: Text('Hard')),
                DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
              ],
              onChanged: (v) => setState(() => _difficulty = v ?? 'medium'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: (_selectedSubjects.isEmpty || _isCreating) ? null : _create,
              child: _isCreating
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Start mock exam'),
            ),
          ],
        ),
      ),
    );
  }
}
