/// Admin Sessions Center screen — Phase 7.3.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_sessions_repository.dart';

// Palette
const _kBg = Color(0xFF0A0E1A);
const _kCard = Color(0xFF131824);
const _kBorder = Color(0xFF1E2433);
const _kAccent = Color(0xFF6E8DFF);
const _kGreen = Color(0xFF4ADE80);
const _kOrange = Color(0xFFF59E0B);
const _kRed = Color(0xFFEF4444);
const _kMuted = Color(0xFF8B94A7);

class AdminSessionsScreen extends ConsumerStatefulWidget {
  const AdminSessionsScreen({super.key});

  @override
  ConsumerState<AdminSessionsScreen> createState() =>
      _AdminSessionsScreenState();
}

class _AdminSessionsScreenState extends ConsumerState<AdminSessionsScreen> {
  final _emailCtrl = TextEditingController();
  bool _adminOnly = false;
  bool _busy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = (email: _emailCtrl.text, adminOnly: _adminOnly);
    final async = ref.watch(sessionsListProvider(filters));

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: _kCard,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                const Icon(Icons.devices, color: _kAccent, size: 22),
                const SizedBox(width: 12),
                const Text(
                  'Sessions actives',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 16),
                async.when(
                  data: (r) => _Badge(
                    label: '${r.total} session(s)',
                    color: _kAccent,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _cleanupExpired,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kOrange,
                    side: const BorderSide(color: _kOrange),
                  ),
                  icon: const Icon(Icons.auto_delete_outlined, size: 16),
                  label: const Text('Nettoyer expirées'),
                ),
              ],
            ),
          ),
          // Filter bar
          Container(
            color: _kCard,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 320,
                  height: 34,
                  child: TextField(
                    controller: _emailCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onSubmitted: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Filtrer par email...',
                      hintStyle: const TextStyle(color: _kMuted, fontSize: 12),
                      prefixIcon:
                          const Icon(Icons.search, color: _kMuted, size: 16),
                      filled: true,
                      fillColor: _kBg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _adminOnly,
                      onChanged: (v) => setState(() => _adminOnly = v ?? false),
                      activeColor: _kAccent,
                    ),
                    const Text(
                      'Admin seulement',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh, color: _kMuted),
                  tooltip: 'Rafraîchir',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          // Table
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _kAccent)),
              error: (e, _) =>
                  Center(child: Text('Erreur: $e', style: const TextStyle(color: _kRed))),
              data: (r) {
                if (r.items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.devices_other, color: _kMuted, size: 48),
                        SizedBox(height: 12),
                        Text('Aucune session active',
                            style: TextStyle(color: _kMuted)),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: r.items
                        .map((s) => _SessionTile(
                              session: s,
                              onRevoke: () => _confirmRevoke(s),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Actions ----------

  Future<void> _cleanupExpired() async {
    setState(() => _busy = true);
    try {
      final r = await ref
          .read(adminSessionsRepositoryProvider)
          .cleanupExpired();
      ref.invalidate(sessionsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🧹 ${r.deletedCount} session(s) expirée(s) supprimée(s)'),
            backgroundColor: _kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: _kRed),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRevoke(SessionRow s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        title: const Text(
          'Révoquer la session ?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Utilisateur : ${s.userEmail ?? s.userId}\n'
          'Créée : ${_formatDate(s.createdAt)}\n\n'
          'L\'utilisateur devra se reconnecter.',
          style: const TextStyle(color: _kMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: _kMuted)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _kRed),
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Révoquer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final r = await ref
          .read(adminSessionsRepositoryProvider)
          .revokeSession(s.id);
      ref.invalidate(sessionsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${r.message}'),
            backgroundColor: _kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: _kRed),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ============================================================
// WIDGETS
// ============================================================

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onRevoke});
  final SessionRow session;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                session.isAdmin ? _kAccent.withOpacity(0.2) : _kBorder,
            child: Icon(
              session.isAdmin ? Icons.admin_panel_settings : Icons.person,
              size: 16,
              color: session.isAdmin ? _kAccent : Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.userEmail ?? session.userId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.id,
                  style: const TextStyle(color: _kMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          if (session.isAdmin)
            const _Badge(label: 'ADMIN', color: _kAccent),
          const SizedBox(width: 8),
          if (session.isExpired)
            const _Badge(label: 'EXPIRÉE', color: _kRed)
          else
            const _Badge(label: 'ACTIVE', color: _kGreen),
          const SizedBox(width: 20),
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Créée',
                  style: TextStyle(color: _kMuted, fontSize: 9),
                ),
                Text(
                  _formatDate(session.createdAt),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expire',
                  style: TextStyle(color: _kMuted, fontSize: 9),
                ),
                Text(
                  _formatDate(session.expiresAt),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onRevoke,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kRed,
              side: const BorderSide(color: _kRed),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.logout, size: 14),
            label: const Text('Révoquer'),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
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

String _formatDate(DateTime d) {
  final l = d.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')} '
      '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}
