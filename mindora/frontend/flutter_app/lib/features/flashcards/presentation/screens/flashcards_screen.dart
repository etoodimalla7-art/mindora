import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/mindora_app_bar.dart';
import '../../data/flashcard_providers.dart';

class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksProvider);

    return Scaffold(
      appBar: const MindoraAppBar(title: 'Flashcards'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Deck'),
      ),
      body: decksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (decks) {
          if (decks.isEmpty) {
            return const Center(
              child: Text('Aucun deck. Crée ton premier !'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: decks.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final deck = decks[i];
              return Card(
                child: ListTile(
                  title: Text(deck.title),
                  subtitle: Text('${deck.cardCount} cartes · ${deck.dueCount} à réviser'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/flashcards/decks/${deck.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouveau Deck'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'Titre du deck'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (ok == true && titleCtrl.text.isNotEmpty) {
      await ref.read(flashcardApiProvider).createDeck(title: titleCtrl.text);
      ref.invalidate(decksProvider);
    }
  }
}
