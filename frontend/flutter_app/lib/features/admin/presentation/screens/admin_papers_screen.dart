import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/network/api_client.dart';
import '../../data/paper_api.dart';
import '../../domain/admin_models.dart';

final paperApiProvider = Provider<PaperApi>((ref) {
  return PaperApi(ref.watch(dioProvider));
});

final adminPapersProvider = FutureProvider<List<AdminPaper>>((ref) async {
  return ref.watch(paperApiProvider).listPapers();
});

class AdminPapersScreen extends ConsumerStatefulWidget {
  const AdminPapersScreen({super.key});

  @override
  ConsumerState<AdminPapersScreen> createState() => _AdminPapersScreenState();
}

class _AdminPapersScreenState extends ConsumerState<AdminPapersScreen> {
  @override
  Widget build(BuildContext context) {
    final papersAsync = ref.watch(adminPapersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin — Papers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Uploader'),
      ),
      body: papersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (papers) {
          if (papers.isEmpty) {
            return const Center(child: Text('Aucun paper uploadé'));
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
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(p),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showUploadDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final systemCtrl = TextEditingController(text: 'GCE');
    final levelCtrl = TextEditingController(text: 'A-Level');
    final yearCtrl = TextEditingController();
    XFile? file;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Uploader un paper'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre')),
                TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Matière')),
                TextField(controller: systemCtrl, decoration: const InputDecoration(labelText: 'Système')),
                TextField(controller: levelCtrl, decoration: const InputDecoration(labelText: 'Niveau')),
                TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Année')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: Text(file == null ? 'Choisir PDF' : file!.name),
                  onPressed: () async {
                    const typeGroup = XTypeGroup(label: 'PDF', extensions: ['pdf']);
                    final f = await openFile(acceptedTypeGroups: [typeGroup]);
                    if (f != null) setState(() => file = f);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Uploader')),
          ],
        ),
      ),
    );

    if (ok == true && file != null) {
      // Capture messenger BEFORE await (safe pattern)
      final messenger = ScaffoldMessenger.of(context);
      final refresh = ref;

      try {
        await refresh.read(paperApiProvider).uploadPaper(
              title: titleCtrl.text,
              subject: subjectCtrl.text,
              examSystem: systemCtrl.text,
              examLevel: levelCtrl.text,
              examYear: int.tryParse(yearCtrl.text),
              file: file!,
            );
        refresh.invalidate(adminPapersProvider);
        messenger.showSnackBar(
          const SnackBar(content: Text('Paper uploadé ✅')),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(AdminPaper paper) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('"${paper.title}" sera supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      // Capture ref BEFORE await
      final refresh = ref;
      await refresh.read(paperApiProvider).deletePaper(paper.id);
      refresh.invalidate(adminPapersProvider);
    }
  }
}
