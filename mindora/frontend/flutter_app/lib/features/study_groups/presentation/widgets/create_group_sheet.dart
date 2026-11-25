import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../data/study_group_providers.dart';

class CreateGroupSheet extends ConsumerStatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  ConsumerState<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<CreateGroupSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _subject = TextEditingController();
  final _examSystem = TextEditingController();
  final _examLevel = TextEditingController();
  bool _isPrivate = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _subject.dispose();
    _examSystem.dispose();
    _examLevel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom doit faire au moins 3 caractères.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(studyGroupRepositoryProvider).createGroup(
            name: name,
            description:
                _description.text.trim().isEmpty ? null : _description.text.trim(),
            subject: _subject.text.trim().isEmpty ? null : _subject.text.trim(),
            examSystem:
                _examSystem.text.trim().isEmpty ? null : _examSystem.text.trim(),
            examLevel:
                _examLevel.text.trim().isEmpty ? null : _examLevel.text.trim(),
            isPrivate: _isPrivate,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: insets + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Créer un groupe d\'étude',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nom du groupe *',
                hintText: 'Ex: GCE A-Level Maths 2025',
                border: OutlineInputBorder(),
              ),
              maxLength: 120,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Décris brièvement le but du groupe',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              maxLength: 1000,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subject,
                    decoration: const InputDecoration(
                      labelText: 'Matière',
                      hintText: 'Maths',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _examLevel,
                    decoration: const InputDecoration(
                      labelText: 'Niveau',
                      hintText: 'A-Level',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _examSystem,
              decoration: const InputDecoration(
                labelText: 'Système d\'examen',
                hintText: 'GCE / Bac / BEPC',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Groupe privé'),
              subtitle: const Text('Seuls les membres invités peuvent voir'),
              value: _isPrivate,
              onChanged: (v) => setState(() => _isPrivate = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}
