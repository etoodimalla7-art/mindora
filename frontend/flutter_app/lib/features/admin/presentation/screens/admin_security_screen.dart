/// Admin Security & Monitoring screen — Phase 7.1.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_security_repository.dart';

// Palette
const _kBg = Color(0xFF0A0E1A);
const _kCard = Color(0xFF131824);
const _kBorder = Color(0xFF1E2433);
const _kAccent = Color(0xFF6E8DFF);
const _kGreen = Color(0xFF4ADE80);
const _kOrange = Color(0xFFF59E0B);
const _kRed = Color(0xFFEF4444);
const _kMuted = Color(0xFF8B94A7);

class AdminSecurityScreen extends ConsumerStatefulWidget {
  const AdminSecurityScreen({super.key});

  @override
  ConsumerState<AdminSecurityScreen> createState() =>
      _AdminSecurityScreenState();
}

class _AdminSecurityScreenState extends ConsumerState<AdminSecurityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Alerts filter
  bool? _alertAckFilter;
  String? _alertSevFilter;
  // Login history filter
  bool? _loginSuccessFilter;
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.security, color: _kAccent, size: 22),
            SizedBox(width: 10),
            Text(
              'Security Center',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kAccent,
          labelColor: Colors.white,
          unselectedLabelColor: _kMuted,
          tabs: const [
            Tab(text: 'System Health'),
            Tab(text: 'Alerts & Logins'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildSystemHealthTab(),
          _buildAlertsLoginsTab(),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 1 — System Health
  // ============================================================

  Widget _buildSystemHealthTab() {
    final healthAsync = ref.watch(systemHealthProvider);
    final metricsAsync = ref.watch(systemMetricsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall status
          healthAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: _kAccent),
            ),
            error: (e, _) => _ErrorBox(message: '$e'),
            data: (h) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OverallStatusCard(health: h),
                const SizedBox(height: 20),
                const Text(
                  'Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: h.services
                      .map((s) => _ServiceCard(service: s))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Metrics
          const Text(
            'Metrics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          metricsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: _kAccent),
            ),
            error: (e, _) => _ErrorBox(message: '$e'),
            data: (m) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  label: 'Utilisateurs',
                  value: '${m.totalUsers}',
                  icon: Icons.people_outline,
                  color: _kAccent,
                ),
                _MetricCard(
                  label: 'Sessions 24h',
                  value: '${m.activeSessions24h}',
                  icon: Icons.devices_outlined,
                  color: _kGreen,
                ),
                _MetricCard(
                  label: 'Login échoués 24h',
                  value: '${m.failedLogins24h}',
                  icon: Icons.block_outlined,
                  color: m.failedLogins24h > 0 ? _kRed : _kGreen,
                ),
                _MetricCard(
                  label: 'Alertes non traitées',
                  value: '${m.unacknowledgedAlerts}',
                  icon: Icons.warning_amber,
                  color: m.unacknowledgedAlerts > 0 ? _kOrange : _kGreen,
                ),
                if (m.databaseSizeMb != null)
                  _MetricCard(
                    label: 'Taille DB',
                    value: '${m.databaseSizeMb!.toStringAsFixed(1)} MB',
                    icon: Icons.storage_outlined,
                    color: _kAccent,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 2 — Alerts & Logins
  // ============================================================

  Widget _buildAlertsLoginsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAlertsSection(),
          const SizedBox(height: 28),
          _buildLoginHistorySection(),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    final filters = (acknowledged: _alertAckFilter, severity: _alertSevFilter);
    final alertsAsync = ref.watch(securityAlertsProvider(filters));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Alertes de sécurité',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            alertsAsync.when(
              data: (r) => _Badge(
                label: '${r.unacknowledged} non traitées',
                color: r.unacknowledged > 0 ? _kOrange : _kGreen,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const Spacer(),
            _filterDropdown<bool?>(
              value: _alertAckFilter,
              items: const [
                (null, 'Toutes'),
                (false, 'Non traitées'),
                (true, 'Traitées'),
              ],
              onChanged: (v) => setState(() => _alertAckFilter = v),
            ),
            const SizedBox(width: 8),
            _filterDropdown<String?>(
              value: _alertSevFilter,
              items: const [
                (null, 'Toutes sévérités'),
                ('low', '🟢 Low'),
                ('medium', '🔵 Medium'),
                ('high', '🟠 High'),
                ('critical', '🔴 Critical'),
              ],
              onChanged: (v) => setState(() => _alertSevFilter = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        alertsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: _kAccent),
            ),
          ),
          error: (e, _) => _ErrorBox(message: '$e'),
          data: (r) {
            if (r.items.isEmpty) {
              return _EmptyBox(
                icon: Icons.shield_outlined,
                message: 'Aucune alerte — tout est calme',
              );
            }
            return Column(
              children: r.items
                  .map((a) => _AlertCard(
                        alert: a,
                        onAck: () async {
                          await ref
                              .read(adminSecurityRepositoryProvider)
                              .acknowledgeAlert(a.id);
                          ref.invalidate(securityAlertsProvider);
                          ref.invalidate(systemMetricsProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Alerte acquittée'),
                                backgroundColor: _kGreen,
                              ),
                            );
                          }
                        },
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoginHistorySection() {
    final filters = (success: _loginSuccessFilter, email: _emailCtrl.text);
    final historyAsync = ref.watch(loginHistoryProvider(filters));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Historique des connexions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            historyAsync.when(
              data: (r) => _Badge(label: '${r.total} entrées', color: _kAccent),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const Spacer(),
            _filterDropdown<bool?>(
              value: _loginSuccessFilter,
              items: const [
                (null, 'Toutes'),
                (true, '✅ Succès'),
                (false, '❌ Échecs'),
              ],
              onChanged: (v) => setState(() => _loginSuccessFilter = v),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 200,
              height: 32,
              child: TextField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                onSubmitted: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Filtrer par email...',
                  hintStyle: const TextStyle(color: _kMuted, fontSize: 11),
                  prefixIcon:
                      const Icon(Icons.search, color: _kMuted, size: 14),
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
          ],
        ),
        const SizedBox(height: 12),
        historyAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: _kAccent),
            ),
          ),
          error: (e, _) => _ErrorBox(message: '$e'),
          data: (r) {
            if (r.items.isEmpty) {
              return _EmptyBox(
                icon: Icons.login,
                message: 'Aucune connexion enregistrée',
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: _kCard,
                border: Border.all(color: _kBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: r.items
                    .map((log) => _LoginRow(row: log))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- Helpers ----------

  Widget _filterDropdown<T>({
    required T value,
    required List<(T, String)> items,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          dropdownColor: _kCard,
          value: value,
          style: const TextStyle(color: Colors.white, fontSize: 11),
          items: items
              .map((it) => DropdownMenuItem<T>(value: it.$1, child: Text(it.$2)))
              .toList(),
          onChanged: (v) => onChanged(v as T),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGETS
// ============================================================

class _OverallStatusCard extends StatelessWidget {
  const _OverallStatusCard({required this.health});
  final SystemHealth health;

  @override
  Widget build(BuildContext context) {
    final color = _overallColor(health.overall);
    final icon = _overallIcon(health.overall);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut global : ${health.overall.toUpperCase()}',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uptime ${health.uptimeSeconds?.toStringAsFixed(0) ?? '?'}s '
                  '· v${health.version ?? '?'} · ${health.env ?? '?'}',
                  style: const TextStyle(color: _kMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _overallColor(String s) {
    switch (s) {
      case 'ok':
        return _kGreen;
      case 'degraded':
        return _kOrange;
      default:
        return _kRed;
    }
  }

  IconData _overallIcon(String s) {
    switch (s) {
      case 'ok':
        return Icons.check_circle_outline;
      case 'degraded':
        return Icons.warning_amber;
      default:
        return Icons.error_outline;
    }
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});
  final ServiceStatus service;

  @override
  Widget build(BuildContext context) {
    final color = service.status == 'ok'
        ? _kGreen
        : service.status == 'degraded'
            ? _kOrange
            : _kRed;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_serviceIcon(service.name), color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  service.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _Badge(label: service.status, color: color),
            ],
          ),
          if (service.latencyMs != null) ...[
            const SizedBox(height: 6),
            Text(
              '${service.latencyMs!.toStringAsFixed(2)} ms',
              style: const TextStyle(color: _kMuted, fontSize: 11),
            ),
          ],
          if (service.detail != null) ...[
            const SizedBox(height: 4),
            Text(
              service.detail!,
              style: const TextStyle(color: _kMuted, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  IconData _serviceIcon(String name) {
    switch (name) {
      case 'database':
        return Icons.storage_outlined;
      case 'redis':
        return Icons.memory;
      case 'storage':
        return Icons.folder_outlined;
      default:
        return Icons.cloud_outlined;
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onAck});
  final SecurityAlert alert;
  final VoidCallback onAck;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          border: Border.all(
            color: alert.acknowledged ? _kBorder : color.withOpacity(0.6),
            width: alert.acknowledged ? 1 : 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              alert.acknowledged
                  ? Icons.check_circle_outline
                  : Icons.warning_amber,
              color: alert.acknowledged ? _kMuted : color,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Badge(label: alert.severity.toUpperCase(), color: color),
                      const SizedBox(width: 8),
                      _Badge(label: alert.type, color: _kAccent),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(alert.createdAt),
                        style: const TextStyle(color: _kMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.message,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  if (alert.metadata.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      alert.metadata.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join(' · '),
                      style: const TextStyle(color: _kMuted, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            if (!alert.acknowledged) ...[
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onAck,
                style: FilledButton.styleFrom(
                  backgroundColor: _kGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Acquitter'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'low':
        return _kGreen;
      case 'medium':
        return _kAccent;
      case 'high':
        return _kOrange;
      case 'critical':
        return _kRed;
      default:
        return _kMuted;
    }
  }
}

class _LoginRow extends StatelessWidget {
  const _LoginRow({required this.row});
  final LoginHistoryRow row;

  @override
  Widget build(BuildContext context) {
    final color = row.success ? _kGreen : _kRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            row.success ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 220,
            child: Text(
              row.email,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          if (row.ip != null)
            _Badge(label: row.ip!, color: _kMuted),
          const SizedBox(width: 12),
          if (!row.success && row.failureReason != null)
            _Badge(label: row.failureReason!, color: _kRed),
          const Spacer(),
          Text(
            _formatDateTime(row.createdAt),
            style: const TextStyle(color: _kMuted, fontSize: 11),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kRed.withOpacity(0.1),
        border: Border.all(color: _kRed.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _kRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _kRed, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: _kMuted, size: 40),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: _kMuted)),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime d) {
  final l = d.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')} '
      '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}
