class FlashcardEntity {
  const FlashcardEntity({
    required this.id, required this.topicTitle, required this.front,
    required this.back, required this.cardType,
  });
  final String id;
  final String topicTitle;
  final String front;
  final String back;
  final String cardType;

  factory FlashcardEntity.fromJson(Map<String, dynamic> json) => FlashcardEntity(
        id: json['id'] as String,
        topicTitle: json['topic_title'] as String,
        front: json['front'] as String,
        back: json['back'] as String,
        cardType: json['card_type'] as String,
      );
}
