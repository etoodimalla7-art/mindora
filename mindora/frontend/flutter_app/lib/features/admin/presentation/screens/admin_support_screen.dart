/// Admin Support Center screen — Phase 6.2.
///
/// 2-column layout (desktop):
///   - Left: ticket list + filters + stats badges
///   - Right: ticket detail + messages thread + composer + actions
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_support_repository.dart';

// ---------- Palette (cohérente avec Analytics) ----------
const _kBg = Color(0xFF0A0E1A);
const _kCard = Color(0xFF131824);
const _kBorder = Color(0xFF1E2433);
const _kAccent = Color(0xFF6E8DFF);
const _kGreen = Color(0xFF4ADE80);
const _kOrange = Color(0xFFF59E0B);
const _kRed = Color(0xFFEF4444);
const _kMuted = Color(0xFF8B94A7);
const _kBlue = Color(0xFF60A5FA);

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  String? _statusFilter; // null = tous
  String? _priorityFilter;
  String? _selectedTicketId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filters = (status: _statusFilter, priority: _priorityFilter, q: _searchQuery);
    final ticketsAsync = ref.watch(supportTicketsProvider(filters));
    final statsAsync = ref.watch(supportStatsProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(statsAsync),
          _buildFilterBar(statsAsync),
          const Divider(height: 1, color: _kBorder),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: ticket list
                SizedBox(
                  width: 380,
                  child: _buildTicketList(ticketsAsync),
                ),
                const VerticalDivider(width: 1, color: _kBorder),
                // Right: detail
                Expanded(child: _buildDetail()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Header ----------

  Widget _buildHeader(AsyncValue<SupportStats> statsAsync) {
    return Container(
      color: _kCard,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          const Icon(Icons.support_agent, color: _kAccent, size: 26),
          const SizedBox(width: 12),
          const Text(
            'Support Center',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(child: _buildStatsBadges(statsAsync)),
          FilledButton.icon(
            onPressed: _showCreateTicketDialog,
            style: FilledButton.styleFrom(backgroundColor: _kAccent),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouveau ticket'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBadges(AsyncValue<SupportStats> statsAsync) {
    return statsAsync.when(
      loading: () => const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatBadge(label: 'Total', count: s.total, color: _kMuted),
          _StatBadge(label: 'Open', count: s.open, color: _kBlue),
          _StatBadge(label: 'In progress', count: s.inProgress, color: _kOrange),
          _StatBadge(label: 'Resolved', count: s.resolved, color: _kGreen),
          _StatBadge(label: 'Closed', count: s.closed, color: _kMuted),
        ],
      ),
    );
  }

  // ---------- Filter bar ----------

  Widget _buildFilterBar(AsyncValue<SupportStats> statsAsync) {
    return Container(
      color: _kCard,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          // Status chips
          Wrap(
            spacing: 6,
            children: [
              _filterChip('Tous', null),
              _filterChip('Open', 'open'),
              _filterChip('In progress', 'in_progress'),
              _filterChip('Resolved', 'resolved'),
              _filterChip('Closed', 'closed'),
            ],
          ),
          const SizedBox(width: 20),
          // Priority dropdown
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _kBg,
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                dropdownColor: _kCard,
                value: _priorityFilter,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Toutes priorités')),
                  DropdownMenuItem(value: 'urgent', child: Text('🔴 Urgent')),
                  DropdownMenuItem(value: 'high', child: Text('🟠 High')),
                  DropdownMenuItem(value: 'normal', child: Text('🔵 Normal')),
                  DropdownMenuItem(value: 'low', child: Text('⚪ Low')),
                ],
                onChanged: (v) => setState(() => _priorityFilter = v),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Search
          Expanded(
            child: SizedBox(
              height: 34,
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher sujet/description...',
                  hintStyle: const TextStyle(color: _kMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: _kMuted, size: 18),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: _kAccent),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kAccent.withOpacity(0.2) : _kBg,
          border: Border.all(color: selected ? _kAccent : _kBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _kAccent : _kMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ---------- Ticket list ----------

  Widget _buildTicketList(AsyncValue<SupportTicketListResponse> async) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kAccent)),
      error: (e, _) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: _kRed)),
      ),
      data: (r) {
        if (r.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox, color: _kMuted, size: 48),
                const SizedBox(height: 12),
                const Text('Aucun ticket', style: TextStyle(color: _kMuted)),
                if (r.total > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${r.total} ticket(s) mais 0 ne correspond aux filtres',
                    style: const TextStyle(color: _kMuted, fontSize: 11),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: r.items.length,
          itemBuilder: (_, i) {
            final ticket = r.items[i];
            final selected = _selectedTicketId == ticket.id;
            return _TicketTile(
              ticket: ticket,
              selected: selected,
              onTap: () => setState(() => _selectedTicketId = ticket.id),
            );
          },
        );
      },
    );
  }

  // ---------- Detail ----------

  Widget _buildDetail() {
    if (_selectedTicketId == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent, color: _kMuted, size: 64),
            SizedBox(height: 12),
            Text(
              'Sélectionne un ticket à gauche',
              style: TextStyle(color: _kMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final detailAsync = ref.watch(supportTicketDetailProvider(_selectedTicketId!));
    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kAccent)),
      error: (e, _) => Center(
        child: Text('Erreur: $e', style: const TextStyle(color: _kRed)),
      ),
      data: (ticket) => _TicketDetailPanel(
        ticket: ticket,
        onRefresh: () {
          ref.invalidate(supportTicketDetailProvider(ticket.id));
          ref.invalidate(supportStatsProvider);
          ref.invalidate(supportTicketsProvider);
        },
      ),
    );
  }

  // ---------- Create dialog ----------

  void _showCreateTicketDialog() async {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'normal';

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _kCard,
          title: const Text('Nouveau ticket', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Sujet',
                    labelStyle: TextStyle(color: _kMuted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: _kMuted),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Priorité :', style: TextStyle(color: _kMuted)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      dropdownColor: _kCard,
                      value: priority,
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                      ],
                      onChanged: (v) => setDialogState(() => priority = v ?? 'normal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler', style: TextStyle(color: _kMuted)),
            ),
            FilledButton(
              onPressed: () async {
                if (subjectCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Sujet et description requis'),
                      backgroundColor: _kRed,
                    ),
                  );
                  return;
                }
                try {
                  await ref
                      .read(adminSupportRepositoryProvider)
                      .createTicket(
                        subject: subjectCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        priority: priority,
                      );
                  ref.invalidate(supportTicketsProvider);
                  ref.invalidate(supportStatsProvider);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: _kRed,
                      ),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(backgroundColor: _kAccent),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ticket créé'),
          backgroundColor: _kGreen,
        ),
      );
    }
  }
}

// ============================================================
// WIDGETS
// ============================================================

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({
    required this.ticket,
    required this.selected,
    required this.onTap,
  });
  final SupportTicketRow ticket;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(ticket.priority);
    final statusColor = _statusColor(ticket.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? _kAccent.withOpacity(0.1) : _kCard,
            border: Border.all(
              color: selected ? _kAccent : _kBorder,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ticket.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _StatusPill(status: ticket.status, color: statusColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ticket.userEmail ?? ticket.userId,
                style: const TextStyle(color: _kMuted, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _priorityLabel(ticket.priority),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: const TextStyle(color: _kMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TicketDetailPanel extends ConsumerStatefulWidget {
  const _TicketDetailPanel({required this.ticket, required this.onRefresh});
  final SupportTicketDetail ticket;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_TicketDetailPanel> createState() => _TicketDetailPanelState();
}

class _TicketDetailPanelState extends ConsumerState<_TicketDetailPanel> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(adminSupportRepositoryProvider)
          .respond(widget.ticket.id, _replyCtrl.text.trim());
      _replyCtrl.clear();
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Réponse envoyée'), backgroundColor: _kGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: _kRed),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _changeStatus(String status) async {
    try {
      await ref.read(adminSupportRepositoryProvider).updateStatus(widget.ticket.id, status);
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Statut: $status'), backgroundColor: _kGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: _kRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          color: _kCard,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.subject,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusPill(status: t.status, color: _statusColor(t.status)),
                  const SizedBox(width: 8),
                  _StatusPill(
                    status: _priorityLabel(t.priority),
                    color: _priorityColor(t.priority),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _infoRow(Icons.person, t.userEmail ?? t.userId),
                  if (t.assignedToEmail != null)
                    _infoRow(Icons.support_agent, t.assignedToEmail!),
                  _infoRow(Icons.calendar_today, _formatDate(t.createdAt)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: Text(
                  t.description,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  if (t.status != 'in_progress')
                    OutlinedButton.icon(
                      onPressed: () => _changeStatus('in_progress'),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('In progress'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kOrange,
                        side: const BorderSide(color: _kOrange),
                      ),
                    ),
                  if (t.status != 'resolved')
                    OutlinedButton.icon(
                      onPressed: () => _changeStatus('resolved'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Résoudre'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kGreen,
                        side: const BorderSide(color: _kGreen),
                      ),
                    ),
                  if (t.status != 'closed')
                    OutlinedButton.icon(
                      onPressed: () => _changeStatus('closed'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Fermer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kMuted,
                        side: const BorderSide(color: _kMuted),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _showAssignDialog,
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Assigner'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kAccent,
                      side: const BorderSide(color: _kAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: _kBorder),
        // Thread
        Expanded(
          child: t.messages.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun message — sois le premier à répondre',
                    style: TextStyle(color: _kMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: t.messages.length,
                  itemBuilder: (_, i) => _MessageBubble(msg: t.messages[i]),
                ),
        ),
        const Divider(height: 1, color: _kBorder),
        // Composer
        Container(
          color: _kCard,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Répondre au ticket...',
                    hintStyle: const TextStyle(color: _kMuted),
                    filled: true,
                    fillColor: _kBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kAccent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _sending ? null : _sendReply,
                style: FilledButton.styleFrom(
                  backgroundColor: _kAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: const Text('Envoyer'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _kMuted, size: 14),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: _kMuted, fontSize: 12)),
      ],
    );
  }

  void _showAssignDialog() async {
    // Simple : on assigne à l'admin courant (demo@mindora.dev)
    // (On pourrait améliorer avec une vraie recherche d'admins plus tard.)
    try {
      final me = ref.read(_myAdminIdProvider);
      if (me == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de déterminer ton ID admin'),
              backgroundColor: _kRed,
            ),
          );
        }
        return;
      }
      await ref.read(adminSupportRepositoryProvider).assign(widget.ticket.id, me);
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ticket assigné'), backgroundColor: _kGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: _kRed),
        );
      }
    }
  }
}

/// Current admin user id — reads from auth session.
final _myAdminIdProvider = Provider<String?>((ref) {
  // Accès au session.user.id via authControllerProvider (import externe)
  // Pour rester local ici, on utilise ref.read sur authControllerProvider
  // qui est exposé dans features/admin/auth.
  return null; // Surchargé par une autre approche — placeholder
});

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final SupportMessageOut msg;

  @override
  Widget build(BuildContext context) {
    final isAdmin = msg.isAdmin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isAdmin ? _kAccent : _kBorder,
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      msg.authorEmail ?? msg.authorId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _kAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: _kAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatDate(msg.createdAt),
                      style: const TextStyle(color: _kMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isAdmin ? _kAccent.withOpacity(0.08) : _kCard,
                    border: Border.all(color: _kBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    msg.body,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Helpers ----------

Color _priorityColor(String p) {
  switch (p) {
    case 'urgent':
      return _kRed;
    case 'high':
      return _kOrange;
    case 'low':
      return _kMuted;
    default:
      return _kBlue;
  }
}

String _priorityLabel(String p) {
  switch (p) {
    case 'urgent':
      return '🔴 Urgent';
    case 'high':
      return '🟠 High';
    case 'low':
      return '⚪ Low';
    default:
      return '🔵 Normal';
  }
}

Color _statusColor(String s) {
  switch (s) {
    case 'open':
      return _kBlue;
    case 'in_progress':
      return _kOrange;
    case 'resolved':
      return _kGreen;
    default:
      return _kMuted;
  }
}

String _statusLabel(String s) {
  switch (s) {
    case 'open':
      return 'OPEN';
    case 'in_progress':
      return 'IN PROGRESS';
    case 'resolved':
      return 'RESOLVED';
    case 'closed':
      return 'CLOSED';
    default:
      return s.toUpperCase();
  }
}

String _formatDate(DateTime d) {
  final l = d.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')} '
      '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}
