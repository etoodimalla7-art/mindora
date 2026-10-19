import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';
import '../../data/planner_providers.dart';
import '../../../../core/design/widgets/celebration.dart';

class CreateExamPlanScreen extends ConsumerStatefulWidget {
  const CreateExamPlanScreen({super.key});

  @override
  ConsumerState<CreateExamPlanScreen> createState() =>
      _CreateExamPlanScreenState();
}

class _CreateExamPlanScreenState extends ConsumerState<CreateExamPlanScreen> {
  String _examSystem = 'GCE';
  String _examLevel = 'ADVANCED_LEVEL';
  String _examName = 'GCE A-Level';
  final Set<String> _subjects = {'Mathematics'};
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  int _dailyMinutes = 90;
  bool _submitting = false;

  static const _allSubjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'Economics',
    'Accounting',
    'English',
    'French',
    'History',
    'Geography',
    'Philosophy',
  ];

  Future<void> _submit() async {
    if (_subjects.isEmpty) {
      _toast('Select at least one subject.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final plan = await ref.read(plannerRepositoryProvider).createExamPlan(
            examSystem: _examSystem,
            examLevel: _examLevel,
            examName: _examName,
            subjects: _subjects.toList(),
            targetDate: _targetDate,
            dailyMinutes: _dailyMinutes,
          );
      if (!mounted) return;
      ref.invalidate(plansListProvider);
      showCelebration(context);
      context.go('/planner/plans/${plan.id}');
    } catch (_) {
      if (!mounted) return;
      _toast('We could not create your plan. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam preparation')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            AppTextField(
              label: 'Examination name',
              hint: 'GCE A-Level',
              onChanged: (v) => _examName = v,
            ),
            const SizedBox(height: AppSpacing.lg),
            _dropdown(
              label: 'Exam system',
              value: _examSystem,
              options: const ['GCE', 'FRANCOPHONE'],
              onChanged: (v) => setState(() => _examSystem = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            _dropdown(
              label: 'Exam level',
              value: _examLevel,
              options: const [
                'ORDINARY_LEVEL',
                'ADVANCED_LEVEL',
                'BEPC',
                'PROBATOIRE',
                'BACCALAUREAT',
                'HND',
                'BTS',
                'LICENCE',
                'MASTER',
              ],
              onChanged: (v) => setState(() => _examLevel = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Subjects', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _allSubjects)
                  AppChip(
                    label: s,
                    tone: AppChipTone.primary,
                    selected: _subjects.contains(s),
                    onTap: () {
                      setState(() {
                        _subjects.contains(s)
                            ? _subjects.remove(s)
                            : _subjects.add(s);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Target date', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            AppSurface(
              padding: const EdgeInsets.all(AppSpacing.lg),
              onTap: _pickDate,
              child: Row(
                children: [
                  const Icon(Icons.event_outlined),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      DateFormat.yMMMMd().format(_targetDate),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Daily study minutes: $_dailyMinutes',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Slider(
              value: _dailyMinutes.toDouble(),
              min: 30,
              max: 240,
              divisions: 7,
              label: '$_dailyMinutes min',
              onChanged: (v) => setState(() => _dailyMinutes = v.round()),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Generate my plan',
              icon: Icons.auto_awesome,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: [
            for (final o in options)
              DropdownMenuItem(
                value: o,
                child: Text(o.replaceAll('_', ' ')),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: now.add(const Duration(days: 3)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }
}
