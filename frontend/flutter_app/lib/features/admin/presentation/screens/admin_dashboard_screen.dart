import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminStatsProvider),
      child: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Vue d\'ensemble', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _Section(title: 'Utilisateurs', children: [
              _StatCard(label: 'Total', value: s.users.total.toString(), color: Colors.blue),
              _StatCard(label: 'Actifs', value: s.users.active.toString(), color: Colors.green),
              _StatCard(label: 'Admins', value: s.users.admins.toString(), color: Colors.amber),
              _StatCard(label: 'Nouveaux (7j)', value: s.users.newThisWeek.toString(), color: Colors.purple),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'Documents', children: [
              _StatCard(label: 'Total', value: s.documents.total.toString(), color: Colors.blue),
              _StatCard(label: 'En attente', value: s.documents.pending.toString(), color: Colors.orange),
              _StatCard(label: 'Approuvés', value: s.documents.approved.toString(), color: Colors.green),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'Épreuves (Papers)', children: [
              _StatCard(label: 'Total', value: s.papers.total.toString(), color: Colors.blue),
              _StatCard(label: 'Publiées', value: s.papers.published.toString(), color: Colors.green),
              _StatCard(label: 'Brouillons', value: s.papers.draft.toString(), color: Colors.orange),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'Activité du jour', children: [
              _StatCard(label: 'Sessions', value: s.activity.sessionsToday.toString(), color: Colors.blue),
              _StatCard(label: 'Uploads', value: s.activity.uploadsToday.toString(), color: Colors.purple),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: children,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
