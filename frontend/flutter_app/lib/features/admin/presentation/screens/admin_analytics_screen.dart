/// Admin Analytics screen — Phase 6.1.
///
/// 4 tabs: Vue d'ensemble · Rétention · Funnel · Rapports.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/admin_analytics_repository.dart';

// ---------- Palette ----------

const _kBg = Color(0xFF0A0E1A);
const _kCard = Color(0xFF131824);
const _kBorder = Color(0xFF1E2433);
const _kAccent = Color(0xFF6E8DFF);
const _kGreen = Color(0xFF4ADE80);
const _kOrange = Color(0xFFF59E0B);
const _kRed = Color(0xFFEF4444);
const _kMuted = Color(0xFF8B94A7);

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  int _retentionWeeks = 8;
  int _funnelDays = 30;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        title: const Text(
          'Analytics avancés',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _kGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Live',
                  style: TextStyle(color: _kGreen, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kAccent,
          labelColor: Colors.white,
          unselectedLabelColor: _kMuted,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Vue d\'ensemble'),
            Tab(text: 'Rétention'),
            Tab(text: 'Funnel'),
            Tab(text: 'Rapports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(),
          _RetentionTab(
            weeks: _retentionWeeks,
            onWeeksChanged: (v) => setState(() => _retentionWeeks = v),
          ),
          _FunnelTab(
            days: _funnelDays,
            onDaysChanged: (v) => setState(() => _funnelDays = v),
          ),
          const _ReportsTab(),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 1 — Overview
// ============================================================

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(analyticsOverviewProvider);
    return overview.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kAccent)),
      error: (e, _) => _ErrorBox(message: 'Erreur: $e'),
      data: (o) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _KpiCard(
              label: 'Utilisateurs',
              value: '${o.usersTotal}',
              hint: '+${o.usersNew7d} (7j)',
              icon: Icons.people_outline,
            ),
            _KpiCard(
              label: 'Actifs 24h',
              value: '${o.usersActive24h}',
              icon: Icons.online_prediction_outlined,
            ),
            _KpiCard(
              label: 'Documents',
              value: '${o.docsTotal}',
              hint: '${o.docsPending} en review',
              icon: Icons.description_outlined,
            ),
            _KpiCard(
              label: 'Épreuves',
              value: '${o.papersTotal}',
              hint: '${o.papersPublished} publiées',
              icon: Icons.quiz_outlined,
            ),
            _KpiCard(
              label: 'Audit 24h',
              value: '${o.auditActions24h}',
              icon: Icons.policy_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TAB 2 — Retention
// ============================================================

class _RetentionTab extends ConsumerWidget {
  const _RetentionTab({required this.weeks, required this.onWeeksChanged});
  final int weeks;
  final ValueChanged<int> onWeeksChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(analyticsRetentionProvider(weeks));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Période :',
                style: TextStyle(color: _kMuted, fontSize: 13),
              ),
              const SizedBox(width: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 4, label: Text('4 sem')),
                  ButtonSegment(value: 8, label: Text('8 sem')),
                  ButtonSegment(value: 12, label: Text('12 sem')),
                  ButtonSegment(value: 26, label: Text('26 sem')),
                ],
                selected: {weeks},
                onSelectionChanged: (s) => onWeeksChanged(s.first),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return _kMuted;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _kAccent.withOpacity(0.25);
                    }
                    return _kCard;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          async.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: _kAccent)),
            error: (e, _) => _ErrorBox(message: 'Erreur: $e'),
            data: (r) {
              if (r.cohorts.isEmpty) {
                return const _EmptyBox(message: 'Aucune cohorte sur la période');
              }
              final maxWeeks = r.cohorts
                  .map((c) => c.retention.length)
                  .fold<int>(0, (a, b) => a > b ? a : b);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rétention par cohorte hebdomadaire',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildHeatmapTable(r.cohorts, maxWeeks),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapTable(List<CohortRow> cohorts, int maxWeeks) {
    return Table(
      defaultColumnWidth: const FixedColumnWidth(72),
      border: TableBorder(
        horizontalInside: BorderSide(color: _kBorder.withOpacity(0.5)),
      ),
      children: [
        // Header row
        TableRow(
          children: [
            _headerCell('Cohorte', align: TextAlign.left),
            _headerCell('Taille'),
            for (var i = 0; i < maxWeeks; i++) _headerCell('S+$i'),
          ],
        ),
        // Data rows
        for (final c in cohorts)
          TableRow(
            children: [
              _dataCell(c.cohortWeek, align: TextAlign.left, bold: true),
              _dataCell('${c.cohortSize}'),
              for (var i = 0; i < maxWeeks; i++)
                _heatCell(i < c.retention.length ? c.retention[i] : null),
            ],
          ),
      ],
    );
  }

  Widget _headerCell(String text, {TextAlign align = TextAlign.center}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          textAlign: align,
          style: const TextStyle(
            color: _kMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _dataCell(String text,
      {TextAlign align = TextAlign.center, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      );

  Widget _heatCell(double? pct) {
    Color bg;
    Color fg;
    if (pct == null) {
      bg = Colors.transparent;
      fg = _kMuted;
    } else if (pct >= 100) {
      bg = _kGreen.withOpacity(0.25);
      fg = _kGreen;
    } else if (pct > 50) {
      bg = _kAccent.withOpacity(0.25);
      fg = _kAccent;
    } else if (pct > 0) {
      bg = _kOrange.withOpacity(0.2);
      fg = _kOrange;
    } else {
      bg = _kBorder;
      fg = _kMuted;
    }
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        pct == null ? '—' : '${pct.toStringAsFixed(0)}%',
        textAlign: TextAlign.center,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ============================================================
// TAB 3 — Funnel
// ============================================================

class _FunnelTab extends ConsumerWidget {
  const _FunnelTab({required this.days, required this.onDaysChanged});
  final int days;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(analyticsFunnelProvider(days));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Période :',
                style: TextStyle(color: _kMuted, fontSize: 13),
              ),
              const SizedBox(width: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7j')),
                  ButtonSegment(value: 30, label: Text('30j')),
                  ButtonSegment(value: 90, label: Text('90j')),
                  ButtonSegment(value: 365, label: Text('365j')),
                ],
                selected: {days},
                onSelectionChanged: (s) => onDaysChanged(s.first),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return _kMuted;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _kAccent.withOpacity(0.25);
                    }
                    return _kCard;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          async.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: _kAccent)),
            error: (e, _) => _ErrorBox(message: 'Erreur: $e'),
            data: (r) {
              if (r.stages.isEmpty) {
                return const _EmptyBox(message: 'Aucune donnée');
              }
              final maxCount = r.stages
                  .map((s) => s.count)
                  .fold<int>(1, (a, b) => a > b ? a : b);
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Funnel d\'engagement',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${r.totalSignups} inscriptions',
                          style: const TextStyle(color: _kMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < r.stages.length; i++)
                      _FunnelBar(
                        stage: r.stages[i],
                        maxCount: maxCount,
                        isFirst: i == 0,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FunnelBar extends StatelessWidget {
  const _FunnelBar({
    required this.stage,
    required this.maxCount,
    required this.isFirst,
  });
  final FunnelStage stage;
  final int maxCount;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final ratio = stage.count / (maxCount == 0 ? 1 : maxCount);
    final pctFromStart = stage.conversionFromStart;

    // Color reflects absolute retention from start (red → orange → accent)
    Color barColor;
    if (pctFromStart >= 70) {
      barColor = _kGreen;
    } else if (pctFromStart >= 40) {
      barColor = _kAccent;
    } else if (pctFromStart >= 10) {
      barColor = _kOrange;
    } else {
      barColor = _kRed;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 160,
                child: Text(
                  stage.label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 22,
                    backgroundColor: _kBorder,
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: Text(
                  '${stage.count} (${pctFromStart.toStringAsFixed(1)}%)',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!isFirst)
            Padding(
              padding: const EdgeInsets.only(left: 172, top: 4),
              child: Text(
                'conversion étape: ${stage.conversionFromPrev.toStringAsFixed(1)}%',
                style: const TextStyle(color: _kMuted, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 4 — Reports / Export CSV
// ============================================================

class _ReportsTab extends ConsumerStatefulWidget {
  const _ReportsTab();

  @override
  ConsumerState<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<_ReportsTab> {
  bool _onlyVerified = false;
  bool _onlyAdmins = false;
  bool _busy = false;
  String? _lastExportPath;
  DateTime? _lastExportAt;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(adminAnalyticsRepositoryProvider);
      final path = await repo.downloadUsersCsv(
        verified: _onlyVerified ? true : null,
        role: _onlyAdmins ? 'admin' : null,
      );
      if (!mounted) return;
      setState(() {
        _lastExportPath = path.isEmpty ? '(navigateur)' : path;
        _lastExportAt = DateTime.now();
      });

      // On mobile: open the file. On web: browser already downloaded it.
      if (path.isNotEmpty) {
        final uri = Uri.file(path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path.isEmpty
              ? '✅ CSV téléchargé par le navigateur'
              : '✅ Export CSV enregistré: ${path.split('/').last}'),
          backgroundColor: _kGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur export: $e'),
          backgroundColor: _kRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.download_outlined, color: _kAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Exporter les utilisateurs (CSV)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Filtres :',
              style: TextStyle(color: _kMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _onlyVerified,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _onlyVerified = v ?? false),
              title: const Text(
                'Email vérifié uniquement',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              activeColor: _kAccent,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _onlyAdmins,
              onChanged:
                  _busy ? null : (v) => setState(() => _onlyAdmins = v ?? false),
              title: const Text(
                'Admins uniquement',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              activeColor: _kAccent,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              style: FilledButton.styleFrom(
                backgroundColor: _kAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(_busy ? 'Export en cours...' : 'Télécharger users.csv'),
            ),
            if (_lastExportAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Dernier export: ${_lastExportAt!.toLocal()}',
                style: const TextStyle(color: _kMuted, fontSize: 11),
              ),
              if (_lastExportPath != null)
                Text(
                  'Fichier: $_lastExportPath',
                  style: const TextStyle(color: _kMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SHARED WIDGETS
// ============================================================

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.hint,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: _kMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: const TextStyle(color: _kMuted, fontSize: 11)),
          ],
        ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRed.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _kRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _kRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Text(message, style: const TextStyle(color: _kMuted)),
    );
  }
}
