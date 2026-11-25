import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin_providers.dart';
import '../../data/admin_users_repository.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showBulkSuspendSheet() async {
    if (_selected.isEmpty) return;
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Suspendre ${_selected.length} utilisateur(s) ?'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Motif de suspension (obligatoire)',
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
            child: const Text('Suspendre'),
          ),
        ],
      ),
    );
    if (ok != true) {
      reasonCtrl.dispose();
      return;
    }

    final repo = ref.read(adminUsersRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result =
          await repo.bulkSuspend(_selected.toList(), reasonCtrl.text.trim());
      if (mounted) {
        setState(() => _selected.clear());
        ref.invalidate(adminUsersProvider(_search));
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${result['succeeded']} suspendu(s), ${result['failed']} échec(s)',
            ),
            backgroundColor: (result['failed'] as int? ?? 0) > 0
                ? Colors.orange
                : Colors.green,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      reasonCtrl.dispose();
    }
  }

  Future<void> _showBulkPromoteDialog() async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Promouvoir ${_selected.length} utilisateur(s) admin ?'),
        content: const Text(
          'Ces utilisateurs auront accès à toutes les fonctionnalités admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Promouvoir'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final repo = ref.read(adminUsersRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await repo.bulkPromote(_selected.toList());
      if (mounted) {
        setState(() => _selected.clear());
        ref.invalidate(adminUsersProvider(_search));
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${result['succeeded']} promu(s), ${result['failed']} échec(s)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(adminUsersProvider(_search));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selected.isEmpty
              ? 'Utilisateurs'
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
                  onPressed: _showBulkSuspendSheet,
                  icon: const Icon(Icons.block, color: Colors.orange),
                  label: const Text('Suspendre',
                      style: TextStyle(color: Colors.orange)),
                ),
                TextButton.icon(
                  onPressed: _showBulkPromoteDialog,
                  icon: const Icon(Icons.upgrade, color: Colors.green),
                  label: const Text('Promouvoir',
                      style: TextStyle(color: Colors.green)),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher email ou nom…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          // List
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Text('Aucun utilisateur',
                        style: theme.textTheme.bodyMedium),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminUsersProvider(_search)),
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final u = users[i];
                      final isSelected = _selected.contains(u.id);
                      return ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selected.add(u.id);
                              } else {
                                _selected.remove(u.id);
                              }
                            });
                          },
                        ),
                        title: Text(u.fullName ?? u.email),
                        subtitle: Text(u.email,
                            style: theme.textTheme.bodySmall),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (u.isAdmin)
                              _Badge(label: 'Admin', color: Colors.amber),
                            if (!u.isActive)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: _Badge(
                                    label: 'Inactif', color: Colors.grey),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () =>
                                  context.push('/admin/users/${u.id}'),
                            ),
                          ],
                        ),
                        onTap: () => context.push('/admin/users/${u.id}'),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
