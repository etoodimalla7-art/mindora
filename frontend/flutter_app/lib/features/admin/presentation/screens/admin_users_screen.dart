import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_search));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher email ou nom…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (users) => users.isEmpty
                ? const Center(child: Text('Aucun utilisateur'))
                : ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final u = users[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: u.isAdmin ? Colors.amber : Colors.blueGrey,
                          child: Icon(u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                              color: Colors.white),
                        ),
                        title: Text(u.email),
                        subtitle: Text(
                          '${u.fullName ?? "(sans nom)"} • ${u.isActive ? "actif" : "désactivé"}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: u.isActive ? 'Désactiver' : 'Activer',
                              icon: Icon(u.isActive ? Icons.block : Icons.check_circle,
                                  color: u.isActive ? Colors.red : Colors.green),
                              onPressed: () async {
                                await ref.read(adminApiProvider).toggleActive(u.id);
                                ref.invalidate(adminUsersProvider(_search));
                              },
                            ),
                            if (!u.isAdmin)
                              IconButton(
                                tooltip: 'Promouvoir admin',
                                icon: const Icon(Icons.upgrade, color: Colors.amber),
                                onPressed: () async {
                                  await ref.read(adminApiProvider).promote(u.id);
                                  ref.invalidate(adminUsersProvider(_search));
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
