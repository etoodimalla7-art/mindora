import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_documents_repository.dart';
import '../widgets/pdf_viewer_sheet.dart';

class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() =>
      _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bulkApprove() async {
    if (_selected.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await ref
          .read(adminDocumentsRepositoryProvider)
          .bulkApprove(_selected.toList());
      if (mounted) {
        setState(() => _selected.clear());
        ref.invalidate(adminDocumentsProvider);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${r['succeeded']} approuvé(s), ${r['failed']} échec(s)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _bulkReject() async {
    if (_selected.isEmpty) return;
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rejeter ${_selected.length} document(s) ?'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Motif (obligatoire)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonCtrl.text.trim().length < 3) return;
              Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (ok != true) {
      reasonCtrl.dispose();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await ref
          .read(adminDocumentsRepositoryProvider)
          .bulkReject(_selected.toList(), reasonCtrl.text.trim());
      if (mounted) {
        setState(() => _selected.clear());
        ref.invalidate(adminDocumentsProvider);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${r['succeeded']} rejeté(s), ${r['failed']} échec(s)',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      reasonCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docsAsync = ref.watch(adminDocumentsProvider);
    final filter = ref.watch(documentsFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selected.isEmpty
              ? 'Modération'
              : '${_selected.length} sélectionné(s)',
        ),
        leading: _selected.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selected.clear()),
              )
            : null,
        actions: _selected.isNotEmpty
            ? [
                TextButton.icon(
                  onPressed: _bulkReject,
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Rejeter',
                      style: TextStyle(color: Colors.red)),
                ),
                TextButton.icon(
                  onPressed: _bulkApprove,
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: const Text('Approuver',
                      style: TextStyle(color: Colors.green)),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher titre ou description…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
              onChanged: (v) {
                ref.read(documentsFilterProvider.notifier).state =
                    filter.copyWith(search: v.isEmpty ? null : v);
              },
            ),
          ),
          // Filters chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _StatusChip(
                  label: 'En attente',
                  selected: filter.status == 'under_review',
                  onTap: () => ref.read(documentsFilterProvider.notifier).state =
                      filter.copyWith(status: 'under_review'),
                ),
                const SizedBox(width: 6),
                _StatusChip(
                  label: 'Approuvés',
                  selected: filter.status == 'approved',
                  onTap: () => ref.read(documentsFilterProvider.notifier).state =
                      filter.copyWith(status: 'approved'),
                ),
                const SizedBox(width: 6),
                _StatusChip(
                  label: 'Rejetés',
                  selected: filter.status == 'rejected',
                  onTap: () => ref.read(documentsFilterProvider.notifier).state =
                      filter.copyWith(status: 'rejected'),
                ),
                const SizedBox(width: 6),
                _StatusChip(
                  label: 'Tous',
                  selected: filter.status == null && !filter.archived,
                  onTap: () => ref.read(documentsFilterProvider.notifier).state =
                      filter.copyWith(clearStatus: true, archived: false),
                ),
                const SizedBox(width: 6),
                _StatusChip(
                  label: 'Archivés',
                  selected: filter.archived,
                  onTap: () => ref.read(documentsFilterProvider.notifier).state =
                      filter.copyWith(clearStatus: true, archived: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: docsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (docs) {
                if (docs.isEmpty) {
                  return Center(
                    child: Text('Aucun document',
                        style: theme.textTheme.bodyMedium),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminDocumentsProvider),
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final isSelected = _selected.contains(d.id);
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selected.add(d.id);
                              } else {
                                _selected.remove(d.id);
                              }
                            }),
                          ),
                          title: Text(d.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${d.category ?? "?"} · ${d.academicLevel ?? "?"} · ${d.sizeFormatted}',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Aperçu PDF',
                                icon: const Icon(Icons.visibility, size: 20),
                                onPressed: () => showPdfViewerSheet(
                                  context,
                                  docId: d.id,
                                  title: d.title,
                                ),
                              ),
                            ],
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
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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
      backgroundColor:
          selected ? theme.colorScheme.primary.withValues(alpha: 0.2) : null,
      side: selected ? BorderSide(color: theme.colorScheme.primary) : null,
    );
  }
}
