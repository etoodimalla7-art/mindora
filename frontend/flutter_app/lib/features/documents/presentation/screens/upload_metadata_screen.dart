import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/widgets.dart';

const _categories = [
  'Mathematics', 'Physics', 'Chemistry', 'Biology', 'Computer Science',
  'Economics', 'Accounting', 'English', 'French', 'History', 'Geography',
  'Philosophy', 'Other',
];

const _levels = [
  'PRIMARY', 'SECONDARY', 'GCE_OL', 'GCE_AL', 'BEPC', 'PROBATOIRE',
  'BACCALAUREAT', 'HND', 'BTS', 'LICENCE', 'MASTER', 'UNIVERSITY',
];

const _docTypes = [
  'course_notes', 'past_paper', 'study_guide', 'exercise_set',
  'textbook', 'summary', 'unknown',
];

class UploadMetadataScreen extends ConsumerStatefulWidget {
  const UploadMetadataScreen({super.key, required this.file});
  final PlatformFile file;

  @override
  ConsumerState<UploadMetadataScreen> createState() =>
      _UploadMetadataScreenState();
}

class _UploadMetadataScreenState extends ConsumerState<UploadMetadataScreen> {
  final _title = TextEditingController();
  String _category = 'Mathematics';
  String _level = 'GCE_AL';
  String _language = 'en';
  String _docType = 'course_notes';
  bool _isExam = false;
  String? _examSystem;
  String? _examName;
  int? _examYear;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _continue() {
    if (_title.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title (min 3 characters).')),
      );
      return;
    }
    context.push(
      '/documents/upload/description',
      extra: {
        'file': widget.file,
        'title': _title.text.trim(),
        'category': _category,
        'level': _level,
        'language': _language,
        'docType': _docType,
        'isExam': _isExam,
        'examSystem': _examSystem,
        'examName': _examName,
        'examYear': _examYear,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Document details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text('Tell us what this document is.',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Accurate metadata helps other students find it.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xxl),

            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Example: Differential equations — course notes',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _dropdown('Category / subject', _category, _categories,
                (v) => setState(() => _category = v)),
            const SizedBox(height: AppSpacing.lg),

            _dropdown('Academic level', _level, _levels,
                (v) => setState(() => _level = v)),
            const SizedBox(height: AppSpacing.lg),

            _dropdown('Language', _language, ['en', 'fr'],
                (v) => setState(() => _language = v)),
            const SizedBox(height: AppSpacing.lg),

            _dropdown('Document type', _docType, _docTypes,
                (v) => setState(() => _docType = v)),
            const SizedBox(height: AppSpacing.lg),

            AppToggle(
              title: 'Related to an official examination',
              subtitle: 'Past papers, exam questions, corrections.',
              value: _isExam,
              onChanged: (v) => setState(() => _isExam = v),
            ),

            if (_isExam) ...[
              const SizedBox(height: AppSpacing.lg),
              _dropdown('Exam system', _examSystem ?? 'GCE',
                  ['GCE', 'FRANCOPHONE', 'HND', 'BTS'],
                  (v) => setState(() => _examSystem = v)),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Exam name',
                  hintText: 'Example: GCE Advanced Level',
                ),
                onChanged: (v) => _examName = v,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  hintText: '2024',
                ),
                onChanged: (v) => _examYear = int.tryParse(v),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Continue',
              icon: Icons.arrow_forward,
              onPressed: _continue,
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
}
