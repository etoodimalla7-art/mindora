import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../../../l10n/app_strings.dart';
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
  String _questionMode = 'mixed';
  int _questionCount = 10;
  int _durationMinutes = 30;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    if (_title.text.trim().length < 3) {
      _toast(s.isFr ? 'Veuillez entrer un titre.' : 'Please enter a title.');
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
            questionMode: _questionMode,
          );
      if (!mounted) return;
      ref.invalidate(mockExamsListProvider);
      context.go('/mock-exams/${exam.id}');
    } catch (_) {
      if (!mounted) return;
      _toast(
        s.isFr
            ? 'Impossible de générer les questions. Assurez-vous d’avoir au moins un document validé dans cette matière.'
            : 'We could not generate questions. Make sure you have at least one approved document on this subject.',
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
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.createMockExamTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              s.isFr ? 'Configurez votre examen' : 'Configure your exam',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              s.isFr
                  ? 'L’IA génère les questions à partir de vos documents validés.'
                  : 'The AI will generate questions from your approved documents.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xxl),

            AppTextField(
              controller: _title,
              label: s.isFr ? 'Titre de l’examen' : 'Exam title',
              hint: s.isFr ? 'Examen d’entraînement' : 'Practice exam',
            ),
            const SizedBox(height: AppSpacing.lg),

            _dropdown(s.subjectLabel, _subject, _subjects,
                (v) => setState(() => _subject = v)),
            const SizedBox(height: AppSpacing.lg),

            _dropdownOptional(s.levelLabel, _level, _levels,
                (v) => setState(() => _level = v)),
            const SizedBox(height: AppSpacing.lg),

            _dropdown(
              s.isFr ? 'Difficulté' : 'Difficulty',
              _difficulty,
              _difficulties,
              (v) => setState(() => _difficulty = v),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(s.questionModeLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'mcq', label: Text(s.modeMcq)),
                ButtonSegment(
                  value: 'true_false',
                  label: Text(s.modeTrueFalse),
                ),
                ButtonSegment(value: 'mixed', label: Text(s.modeMixed)),
              ],
              selected: {_questionMode},
              onSelectionChanged: (sel) =>
                  setState(() => _questionMode = sel.first),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              s.isFr
                  ? 'Nombre de questions : $_questionCount'
                  : 'Number of questions: $_questionCount',
              style: theme.textTheme.labelLarge,
            ),
            Slider(
              value: _questionCount.toDouble(),
              min: 3,
              max: 30,
              divisions: 27,
              label: '$_questionCount',
              onChanged: (v) =>
                  setState(() => _questionCount = v.round()),
            ),

            Text(
              s.isFr
                  ? 'Durée : $_durationMinutes min'
                  : 'Duration: $_durationMinutes min',
              style: theme.textTheme.labelLarge,
            ),
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
              label: s.isFr ? 'Générer l’examen' : 'Generate exam with AI',
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
