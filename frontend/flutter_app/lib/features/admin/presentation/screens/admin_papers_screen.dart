import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/network/api_client.dart';
import '../../data/paper_api.dart';
import '../../domain/admin_models.dart';

final paperApiProvider = Provider<PaperApi>((ref) {
  return PaperApi(ref.watch(dioProvider));
});

class PapersFilter {
  const PapersFilter({
    this.subject,
    this.examSystem,
    this.examLevel,
    this.examYear,
    this.search,
  });
  final String? subject;
  final String? examSystem;
  final String? examLevel;
  final int? examYear;
  final String? search;

  PapersFilter copyWith({
    String? subject,
    String? examSystem,
    String? examLevel,
    int? examYear,
    String? search,
    bool clearSubject = false,
    bool clearExamSystem = false,
    bool clearExamLevel = false,
    bool clearExamYear = false,
    bool clearSearch = false,
  }) =>
      PapersFilter(
        subject: clearSubject ? null : (subject ?? this.subject),
        examSystem: clearExamSystem ? null : (examSystem ?? this.examSystem),
        examLevel: clearExamLevel ? null : (examLevel ?? this.examLevel),
        examYear: clearExamYear ? null : (examYear ?? this.examYear),
        search: clearSearch ? null : (search ?? this.search),
      );
}

final papersFilterProvider =
    StateProvider<PapersFilter>((_) => const PapersFilter());

final adminPapersProvider = FutureProvider<List<AdminPaper>>((ref) async {
  final f = ref.watch(papersFilterProvider);
  return ref.watch(paperApiProvider).listPapers(
        subject: f.subject,
        examSystem: f.examSystem,
        examLevel: f.examLevel,
        examYear: f.examYear,
        search: f.search,
      );
});

class AdminPapersScreen extends ConsumerStatefulWidget {
  const AdminPapersScreen({super.key});

  @override
  ConsumerState<AdminPapersScreen> createState() => _AdminPapersScreenState();
}

class _AdminPapersScreenState extends ConsumerState<AdminPapersScreen> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Step 1: pick files
  /// Step 2: ask metadata
  /// Step 3: show progress
  Future<void> _pickAndUploadMultiple() async {
    const typeGroup = XTypeGroup(
      label: 'PDF',
      extensions: ['pdf'],
      mimeTypes: ['application/pdf'],
    );

    // ──────────────────────────────────────────────
    // Step 1 — Pick files FIRST (no dialog yet)
    // ──────────────────────────────────────────────
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty || !mounted) return;

    // ──────────────────────────────────────────────
    // Step 2 — Ask metadata
    // ──────────────────────────────────────────────
    final meta = await showDialog<_UploadMeta>(
      context: context,
      builder: (_) => const _UploadMetaDialog(),
    );
    if (meta == null || !mounted) return;

    // ──────────────────────────────────────────────
    // Step 3 — Show progress + upload
    // ──────────────────────────────────────────────
    int done = 0;
    int okCount = 0;
    int failCount = 0;
    bool uploading = true;

    final progressCtrl = StreamController<void>.broadcast();

    // Show the progress dialog WITHOUT awaiting it
    // (so we can pop it manually when done)
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Upload en cours...'),
          content: StreamBuilder<void>(
            stream: progressCtrl.stream,
            builder: (_, __) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: files.isEmpty ? 0 : done / files.length,
                  ),
                  const SizedBox(height: 12),
                  Text('$done / ${files.length}'),
                  if (failCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '$failCount erreur(s)',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );

    try {
      final api = ref.read(paperApiProvider);
      for (final file in files) {
        try {
          final baseName = file.name
              .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
          await api.uploadPaper(
            title: baseName.isEmpty ? file.name : baseName,
            subject: meta.subject,
            examSystem: meta.examSystem,
            examLevel: meta.examLevel,
            examYear: meta.examYear,
            file: file,
          );
          okCount++;
        } catch (e) {
          failCount++;
          debugPrint('[UPLOAD] fail ${file.name}: $e');
        } finally {
          done++;
          progressCtrl.add(null);
        }
      }
    } finally {
      uploading = false;
      progressCtrl.close();
    }

    if (!mounted) return;
    // Close the progress dialog
    if (uploading == false) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    ref.invalidate(adminPapersProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$okCount upload(s), $failCount erreur(s)'),
        backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer ${_selected.length} paper(s) ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;

    final api = ref.read(paperApiProvider);
    final ids = _selected.toList();
    int deleted = 0;
    for (final id in ids) {
      try {
        await api.deletePaper(id);
        deleted++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _selected.clear());
    ref.invalidate(adminPapersProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$deleted paper(s) supprimé(s)')),
    );
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _editPaper(AdminPaper paper) async {
    final updated = await showDialog<AdminPaper>(
      context: context,
      builder: (_) => _EditPaperDialog(paper: paper),
    );
    if (updated != null && mounted) {
      ref.invalidate(adminPapersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ "${updated.title}" mis à jour')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final papersAsync = ref.watch(adminPapersProvider);
    final filter = ref.watch(papersFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selected.isEmpty
              ? 'Admin — Papers'
              : '${_selected.length} sélectionné(s)',
        ),
        leading: _selected.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selected.clear()),
              )
            : null,
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteSelected,
            ),
        ],
      ),
      floatingActionButton: _selected.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _pickAndUploadMultiple,
              icon: const Icon(Icons.upload_file),
              label: const Text('Uploader (multiple)'),
            )
          : null,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher par titre...',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(papersFilterProvider.notifier).state =
                              filter.copyWith(clearSearch: true);
                        },
                      ),
              ),
              onChanged: (v) {
                ref.read(papersFilterProvider.notifier).state =
                    filter.copyWith(search: v.isEmpty ? null : v);
              },
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Wrap(
              spacing: 6,
              children: [
                _FilterChip(
                  label: filter.examSystem ?? 'Système',
                  selected: filter.examSystem != null,
                  onTap: () => _showFilterMenu(
                    context,
                    title: 'Système',
                    options: ['GCE', 'FRANCOPHONE', 'HND', 'BTS'],
                    current: filter.examSystem,
                    onSelect: (v) => ref
                        .read(papersFilterProvider.notifier)
                        .state = filter.copyWith(examSystem: v),
                    onClear: () => ref
                        .read(papersFilterProvider.notifier)
                        .state = filter.copyWith(clearExamSystem: true),
                  ),
                ),
                _FilterChip(
                  label: filter.examLevel ?? 'Niveau',
                  selected: filter.examLevel != null,
                  onTap: () => _showFilterMenu(
                    context,
                    title: 'Niveau',
                    options: [
                      'O-Level', 'A-Level', 'BEPC', 'PROBATOIRE',
                      'BACCALAUREAT', 'HND', 'BTS', 'LICENCE', 'MASTER'
                    ],
                    current: filter.examLevel,
                    onSelect: (v) => ref
                        .read(papersFilterProvider.notifier)
                        .state = filter.copyWith(examLevel: v),
                    onClear: () => ref
                        .read(papersFilterProvider.notifier)
                        .state = filter.copyWith(clearExamLevel: true),
                  ),
                ),
                _FilterChip(
                  label: filter.subject ?? 'Matière',
                  selected: filter.subject != null,
                  onTap: () => _showFilterMenu(
                    context,
                    title: 'Matière',
                    options: [
                      'Mathematics', 'Physics', 'Chemistry', 'Biology',
                      'English', 'French', 'History', 'Geography',
                      'Economics', 'Accounting', 'Computer Science',
                      'Philosophy', 'Other'
                    ],
                    current: filter.subject,
                    onSelect: (v) => ref
                        .read(papersFilterProvider.notifier)
                        .state = filter.copyWith(subject: v),
                    onClear: () => ref
                        .read(papersFilterProvider.notifier)
                        .state = filter.copyWith(clearSubject: true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: papersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (papers) {
                if (papers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucun paper.\nUpload plusieurs PDF d\'un coup avec le bouton en bas.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminPapersProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, 80),
                    itemCount: papers.length,
                    itemBuilder: (_, i) {
                      final p = papers[i];
                      final isSelected = _selected.contains(p.id);
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                          leading: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.blue)
                              : const Icon(Icons.picture_as_pdf,
                                  color: Colors.red),
                          title: Text(p.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${p.subject} · ${p.examSystem} ${p.examLevel}'
                            '${p.examYear != null ? " · ${p.examYear}" : ""}'
                            '\n${p.downloadCount} téléchargement(s)',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                          selected: isSelected,
                          onLongPress: () => _toggleSelect(p.id),
                          onTap: () {
                            if (_selected.isNotEmpty) _toggleSelect(p.id);
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') _editPaper(p);
                              if (action == 'delete') {
                                _selected.clear();
                                _selected.add(p.id);
                                _deleteSelected();
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'edit', child: Text('Modifier')),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer',
                                      style: TextStyle(color: Colors.red))),
                            ],
                          ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterMenu(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String? current,
    required void Function(String?) onSelect,
    required VoidCallback onClear,
  }) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, '__CLEAR__'),
            child: const Text('Tous', style: TextStyle(fontStyle: FontStyle.italic)),
          ),
          ...options.map(
            (o) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, o),
              child: Text(o, style: TextStyle(
                fontWeight: current == o ? FontWeight.bold : FontWeight.normal,
              )),
            ),
          ),
        ],
      ),
    );
    if (selected == '__CLEAR__') {
      onClear();
    } else if (selected != null) {
      onSelect(selected);
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.2)
          : null,
      side: selected ? BorderSide(color: theme.colorScheme.primary) : null,
    );
  }
}

class _UploadMeta {
  const _UploadMeta({
    required this.subject,
    required this.examSystem,
    required this.examLevel,
    this.examYear,
  });
  final String subject;
  final String examSystem;
  final String examLevel;
  final int? examYear;
}

class _UploadMetaDialog extends StatefulWidget {
  const _UploadMetaDialog();

  @override
  State<_UploadMetaDialog> createState() => _UploadMetaDialogState();
}

class _UploadMetaDialogState extends State<_UploadMetaDialog> {
  String _subject = 'Mathematics';
  String _examSystem = 'GCE';
  String _examLevel = 'A-Level';
  final _yearCtrl = TextEditingController();

  @override
  void dispose() {
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Métadonnées pour tous les PDF'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _subject,
              decoration: const InputDecoration(labelText: 'Matière'),
              items: [
                'Mathematics', 'Physics', 'Chemistry', 'Biology', 'English',
                'French', 'History', 'Geography', 'Economics', 'Accounting',
                'Computer Science', 'Philosophy', 'Other'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _subject = v ?? 'Mathematics'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _examSystem,
              decoration: const InputDecoration(labelText: 'Système'),
              items: ['GCE', 'FRANCOPHONE', 'HND', 'BTS']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _examSystem = v ?? 'GCE'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _examLevel,
              decoration: const InputDecoration(labelText: 'Niveau'),
              items: [
                'O-Level', 'A-Level', 'BEPC', 'PROBATOIRE', 'BACCALAUREAT',
                'HND', 'BTS', 'LICENCE', 'MASTER'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _examLevel = v ?? 'A-Level'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Année (optionnel)',
                hintText: '2023',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Les titres seront dérivés du nom de chaque fichier.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _UploadMeta(
              subject: _subject,
              examSystem: _examSystem,
              examLevel: _examLevel,
              examYear: int.tryParse(_yearCtrl.text),
            ),
          ),
          child: const Text('Uploader'),
        ),
      ],
    );
  }
}

class _EditPaperDialog extends ConsumerStatefulWidget {
  const _EditPaperDialog({required this.paper});
  final AdminPaper paper;

  @override
  ConsumerState<_EditPaperDialog> createState() => _EditPaperDialogState();
}

class _EditPaperDialogState extends ConsumerState<_EditPaperDialog> {
  late final TextEditingController _titleCtrl;
  late String _subject;
  late String _examSystem;
  late String _examLevel;
  late final TextEditingController _yearCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.paper.title);
    _subject = widget.paper.subject;
    _examSystem = widget.paper.examSystem;
    _examLevel = widget.paper.examLevel;
    _yearCtrl = TextEditingController(
      text: widget.paper.examYear?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await ref.read(paperApiProvider).updatePaper(
            id: widget.paper.id,
            title: _titleCtrl.text.trim(),
            subject: _subject,
            examSystem: _examSystem,
            examLevel: _examLevel,
            examYear: int.tryParse(_yearCtrl.text),
          );
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le paper'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _subject,
              decoration: const InputDecoration(labelText: 'Matière'),
              items: [
                'Mathematics', 'Physics', 'Chemistry', 'Biology', 'English',
                'French', 'History', 'Geography', 'Economics', 'Accounting',
                'Computer Science', 'Philosophy', 'Other'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _subject = v ?? _subject),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _examSystem,
              decoration: const InputDecoration(labelText: 'Système'),
              items: ['GCE', 'FRANCOPHONE', 'HND', 'BTS']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _examSystem = v ?? _examSystem),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _examLevel,
              decoration: const InputDecoration(labelText: 'Niveau'),
              items: [
                'O-Level', 'A-Level', 'BEPC', 'PROBATOIRE', 'BACCALAUREAT',
                'HND', 'BTS', 'LICENCE', 'MASTER'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _examLevel = v ?? _examLevel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Année'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
