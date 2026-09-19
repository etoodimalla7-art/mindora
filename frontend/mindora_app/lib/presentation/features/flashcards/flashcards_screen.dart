import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../domain/flashcards/flashcard_entity.dart';
import '../../providers/flashcards_providers.dart';
import '../../shared_widgets/empty_state.dart';

/// Section 38: review due flashcards one at a time, flip to reveal the
/// answer, then self-rate known/uncertain/forgotten to drive spaced
/// repetition. Reached with a topic argument from Learn/the AI tutor.
class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key, required this.topicTitle, this.sourceDocumentId});
  final String topicTitle;
  final String? sourceDocumentId;

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  List<FlashcardEntity> _cards = [];
  int _index = 0;
  bool _showBack = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(flashcardsRepositoryProvider);
      var due = await repo.listDue(topic: widget.topicTitle);
      if (due.isEmpty) {
        due = await repo.generate(topicTitle: widget.topicTitle, sourceDocumentId: widget.sourceDocumentId);
      }
      setState(() {
        _cards = due;
        _index = 0;
        _showBack = false;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _error = 'Something went wrong loading your flashcards. Please try again.';
      });
    }
  }

  Future<void> _rate(String state) async {
    final card = _cards[_index];
    try {
      await ref.read(flashcardsRepositoryProvider).review(card.id, state);
    } catch (_) {
      // Non-fatal: continue the session locally even if the rating
      // failed to save; the card will simply reappear as due later.
    }
    if (_index + 1 < _cards.length) {
      setState(() {
        _index++;
        _showBack = false;
      });
    } else {
      setState(() => _cards = []); // session complete
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Flashcards — ${widget.topicTitle}')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? EmptyState(icon: Icons.wifi_off_rounded, title: 'Something went wrong', message: _error!, actionLabel: 'Retry', onAction: _load)
                : _cards.isEmpty
                    ? EmptyState(
                        icon: Icons.celebration_outlined,
                        title: 'All caught up!',
                        message: 'No flashcards due right now for this topic.',
                        actionLabel: 'Generate more',
                        onAction: _load,
                      )
                    : Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            LinearProgressIndicator(value: (_index + 1) / _cards.length),
                            const SizedBox(height: AppSpacing.sm),
                            Text('${_index + 1} of ${_cards.length}', style: theme.textTheme.bodyMedium),
                            const SizedBox(height: AppSpacing.lg),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _showBack = !_showBack),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    child: Center(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          _showBack ? _cards[_index].back : _cards[_index].front,
                                          style: theme.textTheme.titleLarge,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _showBack ? 'Tap to see the question' : 'Tap the card to reveal the answer',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (_showBack)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _rate('forgotten'),
                                      child: const Text('Forgotten'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _rate('uncertain'),
                                      child: const Text('Uncertain'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _rate('known'),
                                      child: const Text('Known'),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
