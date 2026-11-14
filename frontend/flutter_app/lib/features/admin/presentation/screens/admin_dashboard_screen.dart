import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_analytics_repository.dart';
import '../../data/admin_events_repository.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overviewAsync = ref.watch(analyticsOverviewProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(analyticsOverviewProvider);
        ref.invalidate(usersTimeseriesProvider(7));
        ref.invalidate(documentsTimeseriesProvider(7));
        ref.invalidate(subjectsBreakdownProvider);
        ref.invalidate(recentActivityProvider);
        await ref.read(analyticsOverviewProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Text('Vue d\'ensemble', style: theme.textTheme.headlineSmall),
              const SizedBox(width: 12),
              ref.watch(adminEventsStreamProvider).when(
                data: (s) => _WsStatusBadge(connected: s is AdminEventConnected),
                loading: () => const _WsStatusBadge(connected: false),
                error: (_, __) => const _WsStatusBadge(connected: false),
              ),
            ],
          ),
          const SizedBox(height: 24),
          overviewAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (o) => Column(
              children: [
                // KPI grid
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _KpiCard(
                      icon: Icons.people_outline,
                      label: 'Utilisateurs',
                      value: '${o.usersTotal}',
                      sub: '+${o.usersNew7d} cette semaine',
                      color: Colors.blue,
                    ),
                    _KpiCard(
                      icon: Icons.folder_outlined,
                      label: 'Documents',
                      value: '${o.docsTotal}',
                      sub: '${o.docsPending} en attente',
                      color: Colors.orange,
                    ),
                    _KpiCard(
                      icon: Icons.check_circle_outline,
                      label: 'Approuvés',
                      value: '${o.docsApproved}',
                      sub: '${o.docsRejected} rejetés',
                      color: Colors.green,
                    ),
                    _KpiCard(
                      icon: Icons.picture_as_pdf,
                      label: 'Épreuves',
                      value: '${o.papersTotal}',
                      sub: '${o.papersPublished} publiées',
                      color: Colors.purple,
                    ),
                    _KpiCard(
                      icon: Icons.shield_outlined,
                      label: 'Actions admin',
                      value: '${o.auditActions24h}',
                      sub: '24 dernières heures',
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Timeseries
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CardWithTitle(
                        title: 'Inscriptions (7j)',
                        child: const _TimeseriesChart(isUsers: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _CardWithTitle(
                        title: 'Documents soumis (7j)',
                        child: const _TimeseriesChart(isUsers: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Breakdowns
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CardWithTitle(
                        title: 'Répartition par matière',
                        child: const _BreakdownList(isSubjects: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _CardWithTitle(
                        title: 'Répartition par système',
                        child: const _BreakdownList(isSubjects: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Recent activity
                _CardWithTitle(
                  title: 'Activité récente',
                  child: const _RecentActivityFeed(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WsStatusBadge extends StatelessWidget {
  const _WsStatusBadge({required this.connected});
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = connected ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(connected ? Icons.circle : Icons.circle_outlined,
              size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            connected ? 'Live' : 'Hors ligne',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sub, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _CardWithTitle extends StatelessWidget {
  const _CardWithTitle({required this.title, required this.child});
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
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _TimeseriesChart extends ConsumerWidget {
  const _TimeseriesChart({required this.isUsers});
  final bool isUsers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = isUsers
        ? ref.watch(usersTimeseriesProvider(7))
        : ref.watch(documentsTimeseriesProvider(7));
    final theme = Theme.of(context);
    return async.when(
      loading: () => const SizedBox(
          height: 120, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SizedBox(height: 120, child: Center(child: Text('$e'))),
      data: (points) {
        if (points.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text('Pas de données',
                  style: theme.textTheme.bodySmall),
            ),
          );
        }
        final maxVal =
            points.map((p) => p.count).reduce((a, b) => a > b ? a : b).toDouble();
        return SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points.map((p) {
              final ratio = maxVal == 0 ? 0.0 : p.count / maxVal;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${p.count}',
                          style: theme.textTheme.labelSmall),
                      const SizedBox(height: 2),
                      Container(
                        height: 100 * ratio,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.date.day}/${p.date.month}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _BreakdownList extends ConsumerWidget {
  const _BreakdownList({required this.isSubjects});
  final bool isSubjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = isSubjects
        ? ref.watch(subjectsBreakdownProvider)
        : ref.watch(examSystemsBreakdownProvider);
    final theme = Theme.of(context);
    return async.when(
      loading: () => const SizedBox(
          height: 120, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SizedBox(height: 120, child: Center(child: Text('$e'))),
      data: (items) {
        if (items.isEmpty) {
          return SizedBox(
            height: 80,
            child: Center(
              child: Text('Aucune donnée',
                  style: theme.textTheme.bodySmall),
            ),
          );
        }
        final total =
            items.fold<int>(0, (acc, it) => acc + it.count).toDouble();
        return Column(
          children: items.take(5).map((it) {
            final ratio = total == 0 ? 0.0 : it.count / total;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(it.label,
                            style: theme.textTheme.bodySmall),
                      ),
                      Text('${it.count}',
                          style: theme.textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 4,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RecentActivityFeed extends ConsumerWidget {
  const _RecentActivityFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentActivityProvider);
    final theme = Theme.of(context);
    return async.when(
      loading: () => const SizedBox(
          height: 120, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SizedBox(height: 120, child: Center(child: Text('$e'))),
      data: (items) {
        if (items.isEmpty) {
          return SizedBox(
            height: 80,
            child: Center(
              child: Text('Aucune activité',
                  style: theme.textTheme.bodySmall),
            ),
          );
        }
        return Column(
          children: items.take(10).map((it) {
            final icon = it.action.startsWith('document.')
                ? Icons.description_outlined
                : it.action.startsWith('user.')
                    ? Icons.person_outline
                    : Icons.shield_outlined;
            final color = it.result == 'error' ? Colors.red : Colors.green;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, size: 20, color: color),
              title: Text(it.action, style: theme.textTheme.bodyMedium),
              subtitle: Text(
                it.resourceType != null
                    ? '${it.resourceType} ${it.resourceId?.substring(0, 8) ?? ""}'
                    : '—',
                style: theme.textTheme.labelSmall,
              ),
              trailing: Text(
                _fmtTime(it.createdAt),
                style: theme.textTheme.labelSmall,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  static String _fmtTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
