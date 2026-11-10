import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/mindora_app_bar.dart';
import '../../../../core/network/api_client.dart';
import '../../data/paper_api.dart';
import '../../domain/paper_models.dart';

final publicPaperApiProvider = Provider<PublicPaperApi>((ref) {
  return PublicPaperApi(ref.watch(dioProvider));
});

final papersProvider = FutureProvider.family<List<Paper>, Map<String, String?>>((ref, filters) async {
  return ref.watch(publicPaperApiProvider).listPapers(
        subject: filters['subject'],
        examSystem: filters['system'],
        examLevel: filters['level'],
      );
});

class PastPapersScreen extends ConsumerStatefulWidget {
  const PastPapersScreen({super.key});

  @override
  ConsumerState<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends ConsumerState<PastPapersScreen> {
  String? _system;
  String? _level;
  String? _subject;

  @override
  Widget build(BuildContext context) {
    final filters = {'system': _system, 'level': _level, 'subject': _subject};
    final papersAsync = ref.watch(papersProvider(filters));

    return Scaffold(
      appBar: const MindoraAppBar(title: 'Past Papers'),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _system,
                    decoration: const InputDecoration(
                      labelText: 'Système',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous')),
                      DropdownMenuItem(value: 'GCE', child: Text('GCE')),
                      DropdownMenuItem(value: 'Francophone', child: Text('Francophone')),
                    ],
                    onChanged: (v) => setState(() => _system = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _level,
                    decoration: const InputDecoration(
                      labelText: 'Niveau',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous')),
                      DropdownMenuItem(value: 'O-Level', child: Text('O-Level')),
                      DropdownMenuItem(value: 'A-Level', child: Text('A-Level')),
                      DropdownMenuItem(value: 'BEPC', child: Text('BEPC')),
                      DropdownMenuItem(value: 'Bac', child: Text('Bac')),
                      DropdownMenuItem(value: 'Licence', child: Text('Licence')),
                      DropdownMenuItem(value: 'Master', child: Text('Master')),
                    ],
                    onChanged: (v) => setState(() => _level = v),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Liste
          Expanded(
            child: papersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (papers) {
                if (papers.isEmpty) {
                  return const Center(child: Text('Aucun paper trouvé.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  itemCount: papers.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final p = papers[i];
                    return ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: Text(p.title),
                      subtitle: Text('${p.subject} · ${p.examSystem} ${p.examLevel} ${p.examYear ?? ""}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () => _download(context, p),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _download(BuildContext context, Paper p) async {
    final url = ref.read(publicPaperApiProvider).downloadUrl(p.id);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de télécharger le fichier')),
        );
      }
    }
  }
}
