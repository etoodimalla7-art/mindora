import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_content_repository.dart';

class AdminContentScreen extends ConsumerStatefulWidget {
  const AdminContentScreen({super.key});

  @override
  ConsumerState<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends ConsumerState<AdminContentScreen> {
  static const _groups = [
    ('onboarding', 'Onboarding'),
    ('general', 'Général'),
    ('system', 'Système'),
    ('legal', 'Légal'),
    ('ai', 'AI'),
    ('announcements', 'Annonces'),
  ];

  String _activeGroup = 'onboarding';

  Future<void> _createNewKey() async {
    final keyCtrl = TextEditingController();
    final frCtrl = TextEditingController();
    final enCtrl = TextEditingController();
    final grpCtrl = TextEditingController(text: _activeGroup);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle clé de contenu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Clé (ex: welcome_message)',
                  helperText: 'Lettres minuscules, chiffres, _ ou . uniquement',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: grpCtrl,
                decoration: const InputDecoration(
                  labelText: 'Groupe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: frCtrl,
                decoration: const InputDecoration(
                  labelText: 'Valeur FR',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: enCtrl,
                decoration: const InputDecoration(
                  labelText: 'Valeur EN',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (keyCtrl.text.trim().length < 2) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (ok != true) {
      keyCtrl.dispose();
      frCtrl.dispose();
      enCtrl.dispose();
      grpCtrl.dispose();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminContentRepositoryProvider).createContent(
            key: keyCtrl.text.trim(),
            valueFr: frCtrl.text,
            valueEn: enCtrl.text,
            group: grpCtrl.text.trim(),
          );
      ref.invalidate(contentListProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Clé créée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      keyCtrl.dispose();
      frCtrl.dispose();
      enCtrl.dispose();
      grpCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentAsync = ref.watch(contentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contenus (CMS)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewKey,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle clé'),
      ),
      body: Column(
        children: [
          // Group tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: _groups.map((g) {
                final selected = _activeGroup == g.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(g.$2),
                    selected: selected,
                    onSelected: (_) => setState(() => _activeGroup = g.$1),
                  ),
                );
              }).toList(),
            ),
          ),
          // List
          Expanded(
            child: contentAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (all) {
                final items =
                    all.where((c) => c.group == _activeGroup).toList();
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune clé dans ce groupe.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ContentCard(item: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends ConsumerStatefulWidget {
  const _ContentCard({required this.item});
  final ContentString item;

  @override
  ConsumerState<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends ConsumerState<_ContentCard> {
  late final TextEditingController _frCtrl;
  late final TextEditingController _enCtrl;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _frCtrl = TextEditingController(text: widget.item.valueFr);
    _enCtrl = TextEditingController(text: widget.item.valueEn);
  }

  @override
  void dispose() {
    _frCtrl.dispose();
    _enCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(adminContentRepositoryProvider).updateContent(
            widget.item.key,
            valueFr: _frCtrl.text,
            valueEn: _enCtrl.text,
          );
      ref.invalidate(contentListProvider);
      if (mounted) setState(() => _dirty = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Contenu sauvegardé'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.item.key,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_dirty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Non sauvegardé',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (widget.item.description != null) ...[
              const SizedBox(height: 2),
              Text(
                widget.item.description!,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _frCtrl,
              decoration: const InputDecoration(
                labelText: 'FR',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
              onChanged: (_) {
                if (!_dirty) setState(() => _dirty = true);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _enCtrl,
              decoration: const InputDecoration(
                labelText: 'EN',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
              onChanged: (_) {
                if (!_dirty) setState(() => _dirty = true);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 16),
                label: const Text('Sauvegarder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
