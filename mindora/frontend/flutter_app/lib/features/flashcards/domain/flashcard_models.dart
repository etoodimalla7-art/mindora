class Deck {
  final String id;
  final String title;
  final String? description;
  final String? subject;
  final int cardCount;
  final int dueCount;

  Deck({
    required this.id,
    required this.title,
    this.description,
    this.subject,
    required this.cardCount,
    required this.dueCount,
  });

  factory Deck.fromJson(Map<String, dynamic> j) => Deck(
        id: j['id'],
        title: j['title'],
        description: j['description'],
        subject: j['subject'],
        cardCount: j['card_count'] ?? 0,
        dueCount: j['due_count'] ?? 0,
      );
}

class Flashcard {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
  });

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
        id: j['id'],
        deckId: j['deck_id'],
        front: j['front'],
        back: j['back'],
        easeFactor: (j['ease_factor'] as num).toDouble(),
        intervalDays: j['interval_days'],
        repetitions: j['repetitions'],
      );
}

class ReviewResult {
  final String cardId;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewAt;

  ReviewResult({
    required this.cardId,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.nextReviewAt,
  });

  factory ReviewResult.fromJson(Map<String, dynamic> j) => ReviewResult(
        cardId: j['card_id'],
        easeFactor: (j['ease_factor'] as num).toDouble(),
        intervalDays: j['interval_days'],
        repetitions: j['repetitions'],
        nextReviewAt: DateTime.parse(j['next_review_at']),
      );
}
