class ReviewQueueItemEntity {
  const ReviewQueueItemEntity({
    required this.id, this.title, this.description, this.category, this.level,
    required this.status, this.detectedSubject, this.detectedLevel, this.qualityScore,
    this.duplicateOfId, this.similarityScore, required this.isExam, required this.validationSummary,
  });
  final String id;
  final String? title;
  final String? description;
  final String? category;
  final String? level;
  final String status;
  final String? detectedSubject;
  final String? detectedLevel;
  final double? qualityScore;
  final String? duplicateOfId;
  final double? similarityScore;
  final bool isExam;
  final List<String> validationSummary;

  factory ReviewQueueItemEntity.fromJson(Map<String, dynamic> json) => ReviewQueueItemEntity(
        id: json['id'] as String,
        title: json['title'] as String?,
        description: json['description'] as String?,
        category: json['category'] as String?,
        level: json['level'] as String?,
        status: json['status'] as String,
        detectedSubject: json['detected_subject'] as String?,
        detectedLevel: json['detected_level'] as String?,
        qualityScore: (json['quality_score'] as num?)?.toDouble(),
        duplicateOfId: json['duplicate_of_id'] as String?,
        similarityScore: (json['similarity_score'] as num?)?.toDouble(),
        isExam: json['is_exam'] as bool? ?? false,
        validationSummary: (json['validation_summary'] as List).cast<String>(),
      );
}
