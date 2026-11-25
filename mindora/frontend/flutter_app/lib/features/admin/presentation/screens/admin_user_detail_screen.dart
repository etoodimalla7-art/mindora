import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_providers.dart';
import '../../data/admin_users_repository.dart';

class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(adminUserDetailProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: userAsync.maybeWhen(
          data: (u) => Text(u.fullName ?? u.email),
          orElse: () => const Text('Utilisateur'),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (u) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            _UserHeader(user: u),
            const SizedBox(height: 24),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.description_outlined,
                    label: 'Documents',
                    value: '${u.documentsCount}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.picture_as_pdf,
                    label: 'Épreuves',
                    value: '${u.papersCount}',
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.devices_outlined,
                    label: 'Sessions',
                    value: '${u.sessionsCount}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Education
            if (u.educationSystem != null || u.subjects.isNotEmpty)
              _Card(
                title: 'Informations éducatives',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (u.educationSystem != null)
                      _Row(label: 'Système', value: u.educationSystem!),
                    if (u.educationLevel != null)
                      _Row(label: 'Niveau', value: u.educationLevel!),
                    if (u.educationProgram != null)
                      _Row(label: 'Programme', value: u.educationProgram!),
                    if (u.subjects.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 6,
                          children: u.subjects
                              .map((s) => Chip(label: Text(s)))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Roles
            _Card(
              title: 'Rôles',
              child: u.roles.isEmpty
                  ? Text('Aucun rôle assigné',
                      style: theme.textTheme.bodySmall)
                  : Wrap(
                      spacing: 6,
                      children: u.roles
                          .map((r) => Chip(label: Text(r)))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 16),

            // Actions
            _Card(
              title: 'Actions',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _revokeSessions(context, ref),
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Révoquer sessions'),
                  ),
                  if (u.isSuspended)
                    FilledButton.icon(
                      onPressed: () => _reactivate(context, ref),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Réactiver'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _suspend(context, ref),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Suspendre'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  if (!u.isAdmin)
                    OutlinedButton.icon(
                      onPressed: () => _promote(context, ref),
                      icon: const Icon(Icons.upgrade, size: 16),
                      label: const Text('Promouvoir admin'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _revokeSessions(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await ref
          .read(adminUsersRepositoryProvider)
          .revokeSessions(userId);
      ref.invalidate(adminUserDetailProvider(userId));
      messenger.showSnackBar(
        SnackBar(content: Text('${r['revoked']} session(s) révoquée(s)')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _suspend(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspendre cet utilisateur ?'),
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
            child: const Text('Suspendre'),
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
      await ref
          .read(adminUsersRepositoryProvider)
          .suspend(userId, reasonCtrl.text.trim());
      ref.invalidate(adminUserDetailProvider(userId));
      ref.invalidate(adminUsersProvider(''));
      messenger.showSnackBar(
        const SnackBar(content: Text('✅ Utilisateur suspendu')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      reasonCtrl.dispose();
    }
  }

  Future<void> _reactivate(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminUsersRepositoryProvider).toggleActive(userId);
      ref.invalidate(adminUserDetailProvider(userId));
      ref.invalidate(adminUsersProvider(''));
      messenger.showSnackBar(
        const SnackBar(content: Text('✅ Utilisateur réactivé')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _promote(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminUsersRepositoryProvider).promote(userId);
      ref.invalidate(adminUserDetailProvider(userId));
      messenger.showSnackBar(
        const SnackBar(content: Text('✅ Utilisateur promu admin')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});
  final AdminUserDetail user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = (user.fullName ?? user.email)
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    final statusColor = user.isSuspended
        ? Colors.red
        : !user.isActive
            ? Colors.grey
            : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Text(initials,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  )),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName ?? user.email,
                      style: theme.textTheme.titleLarge),
                  Text(user.email, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(user.statusLabel,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (user.isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Admin',
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  if (user.suspensionReason != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Motif: ${user.suspensionReason}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Inscrit le',
                    style: theme.textTheme.labelSmall),
                Text(
                  '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.bold)),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                )),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
