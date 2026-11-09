import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/widgets/mindora_app_bar.dart';
import '../../data/flashcard_providers.dart';
import '../../domain/flashcard_models.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.deckId});
  final String deckId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _showBack = false;
  int _currentIndex = 0;
  List<Flashcard> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await ref.read(flashcardApiProvider).getDueCards(widget.deckId);
    if (mounted) {
      setState(() {
        _cards = cards;
        _currentIndex = 0;
        _showBack = false;
        _loading = false;
      });
    }
  }

  Future<void> _review(int quality) async {
    if (_cards.isEmpty) return;
    final card = _cards[_currentIndex];
    await ref.read(flashcardApiProvider).reviewCard(cardId: card.id, quality: quality);
    
    // Next card
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _showBack = false;
      });
    } else {
      // End of queue
      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(decksProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: const MindoraAppBar(title: 'Révision'),
        body: const Center(child: Text('Toutes les cartes sont à jour ! 🎉')),
      );
    }

    final card = _cards[_currentIndex];

    return Scaffold(
      appBar: MindoraAppBar(title: 'Révision ${_currentIndex + 1}/${_cards.length}'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _showBack = !_showBack),
                  child: Card(
                    elevation: 4,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showBack ? 'RÉPONSE' : 'QUESTION',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showBack ? card.back : card.front,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!_showBack)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton(
                  onPressed: () => setState(() => _showBack = true),
                  child: const Text('Voir la réponse'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () => _review(1), // Hard
                        child: const Text('Difficile'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                        onPressed: () => _review(3), // Good
                        child: const Text('Bien'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => _review(5), // Easy
                        child: const Text('Facile'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
