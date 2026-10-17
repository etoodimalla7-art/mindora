import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_providers.dart';

class AdminPapersScreen extends ConsumerWidget {
  const AdminPapersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(adminPapersProvider);
    return Scaffold(
      body: papersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (papers) => papers.isEmpty
            ? const Center(child: Text('Aucune épreuve uploadée'))
            : ListView.separated(
                itemCount: papers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = papers[i];
                  return ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(p.title),
                    subtitle: Text('${p.subject} • ${p.examSystem} ${p.examLevel} '
                        '${p.examYear ?? ""} • ${(p.fileSize / 1024).toStringAsFixed(0)} KB'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Supprimer ?'),
                            content: Text('"${p.title}" sera supprimé.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await ref.read(adminApiProvider).deletePaper(p.id);
                          ref.invalidate(adminPapersProvider);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.upload_file),
        label: const Text('Uploader'),
        onPressed: () => _showUploadDialog(context, ref),
      ),
    );
  }

  Future<void> _showUploadDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final systemCtrl = TextEditingController(text: 'GCE');
    final levelCtrl = TextEditingController(text: 'A-Level');
    final yearCtrl = TextEditingController();
    File? file;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Uploader une épreuve'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre *')),
                TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Matière *')),
                TextField(controller: systemCtrl, decoration: const InputDecoration(labelText: 'Système (GCE/BAC…) *')),
                TextField(controller: levelCtrl, decoration: const InputDecoration(labelText: 'Niveau (O-Level/A-Level…) *')),
                TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Année')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: Text(file == null ? 'Choisir PDF/DOC' : file!.path.split('/').last),
                  onPressed: () async {
                    const typeGroup = XTypeGroup(label: 'Documents', extensions: ['pdf', 'doc', 'docx']);
                    final f = await openFile(acceptedTypeGroups: [typeGroup]);
                    if (f != null) setState(() => file = File(f.path));
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Uploader'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || file == null) return;
    try {
      await ref.read(adminApiProvider).uploadPaper(
            title: titleCtrl.text,
            subject: subjectCtrl.text,
            examSystem: systemCtrl.text,
            examLevel: levelCtrl.text,
            examYear: int.tryParse(yearCtrl.text),
            file: file!,
          );
      ref.invalidate(adminPapersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Épreuve uploadée ✅')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
