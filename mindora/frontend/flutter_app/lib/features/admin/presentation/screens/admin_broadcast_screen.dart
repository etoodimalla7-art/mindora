import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_content_repository.dart';

class AdminBroadcastScreen extends ConsumerStatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  ConsumerState<AdminBroadcastScreen> createState() =>
      _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends ConsumerState<AdminBroadcastScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _scheduledCtrl = TextEditingController();

  String? _role;
  String? _level;
  String? _system;
  bool _sending = false;
  DateTime? _scheduledAt;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _scheduledCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titre et message obligatoires')),
      );
      return;
    }

    final target = <String, dynamic>{};
    if (_role != null) target['role'] = _role;
    if (_level != null) target['level'] = _level;
    if (_system != null) target['system'] = _system;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      final b = await ref.read(adminContentRepositoryProvider).createBroadcast(
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            targetCriteria: target,
            scheduledAt: _scheduledAt,
          );
      ref.invalidate(broadcastsListProvider);
      if (mounted) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _scheduledCtrl.clear();
        setState(() {
          _role = null;
          _level = null;
          _system = null;
          _scheduledAt = null;
        });
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _scheduledAt != null
                ? '✅ Broadcast programmé'
                : '✅ Envoyé à ${b.sentCount} utilisateurs',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledAt ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _scheduledCtrl.text = _fmt(_scheduledAt!);
    });
  }

  static String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final broadcastsAsync = ref.watch(broadcastsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcasts'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Composer
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nouveau broadcast',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Titre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bodyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Text('Ciblage (optionnel)',
                      style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _role,
                          decoration: const InputDecoration(
                            labelText: 'Rôle',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Tous')),
                            DropdownMenuItem(
                                value: 'admin', child: Text('Admins')),
                            DropdownMenuItem(
                                value: 'user', child: Text('Étudiants')),
                          ],
                          onChanged: (v) => setState(() => _role = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _system,
                          decoration: const InputDecoration(
                            labelText: 'Système',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Tous')),
                            DropdownMenuItem(
                                value: 'Anglophone',
                                child: Text('Anglophone')),
                            DropdownMenuItem(
                                value: 'Francophone',
                                child: Text('Francophone')),
                          ],
                          onChanged: (v) => setState(() => _system = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _level,
                    decoration: const InputDecoration(
                      labelText: 'Niveau',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous')),
                      DropdownMenuItem(value: 'GCE_OL', child: Text('GCE O-Level')),
                      DropdownMenuItem(value: 'GCE_AL', child: Text('GCE A-Level')),
                      DropdownMenuItem(value: 'BEPC', child: Text('BEPC')),
                      DropdownMenuItem(value: 'BACCALAUREAT', child: Text('Baccalauréat')),
                      DropdownMenuItem(value: 'LICENCE', child: Text('Licence')),
                      DropdownMenuItem(value: 'MASTER', child: Text('Master')),
                    ],
                    onChanged: (v) => setState(() => _level = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text(
                          _scheduledAt == null
                              ? 'Programmer'
                              : _fmt(_scheduledAt!),
                        ),
                      ),
                      if (_scheduledAt != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => setState(() {
                            _scheduledAt = null;
                            _scheduledCtrl.clear();
                          }),
                          child: const Text('Annuler'),
                        ),
                      ],
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(_scheduledAt != null
                                ? Icons.schedule_send
                                : Icons.send,
                                size: 16),
                        label: Text(
                          _sending
                              ? 'Envoi...'
                              : (_scheduledAt != null
                                  ? 'Programmer'
                                  : 'Envoyer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Historique', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          broadcastsAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Text('Erreur: $e'),
            data: (list) {
              if (list.isEmpty) {
                return Text(
                  'Aucun broadcast envoyé pour l\'instant.',
                  style: theme.textTheme.bodySmall,
                );
              }
              return Column(
                children: list.map((b) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: b.isPending
                            ? Colors.orange.withValues(alpha: 0.15)
                            : Colors.green.withValues(alpha: 0.15),
                        child: Icon(
                          b.isPending ? Icons.schedule : Icons.check,
                          color: b.isPending ? Colors.orange : Colors.green,
                          size: 18,
                        ),
                      ),
                      title: Text(b.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.body, maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (b.sentCount > 0)
                                _Badge(
                                  label: '${b.sentCount} envoyés',
                                  color: Colors.green,
                                ),
                              if (b.isPending && b.scheduledAt != null)
                                _Badge(
                                  label: 'Programmé ${_fmt(b.scheduledAt!)}',
                                  color: Colors.orange,
                                ),
                              for (final entry in b.targetCriteria.entries)
                                _Badge(
                                  label: '${entry.key}: ${entry.value}',
                                  color: theme.colorScheme.primary,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
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
