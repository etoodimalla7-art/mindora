class DocumentEntity {
  const DocumentEntity({
    required this.id,
    this.title,
    this.description,
    this.category,
    this.level,
    this.language,
    required this.originalFilename,
    required this.status,
  });

  final String id;
  final String? title;
  final String? description;
  final String? category;
  final String? level;
  final String? language;
  final String originalFilename;
  final String status;

  factory DocumentEntity.fromJson(Map<String, dynamic> json) => DocumentEntity(
        id: json['id'] as String,
        title: json['title'] as String?,
        description: json['description'] as String?,
        category: json['category'] as String?,
        level: json['level'] as String?,
        language: json['language'] as String?,
        originalFilename: json['original_filename'] as String,
        status: json['status'] as String,
      );
}

/// Section 27: the full document lifecycle. UI maps each status to a
/// label/color rather than showing the raw enum string.
enum DocumentStatus { draft, uploading, processing, underReview, approved, rejected, needsRevision, archived, removed }

DocumentStatus documentStatusFromString(String value) {
  switch (value) {
    case 'Draft': return DocumentStatus.draft;
    case 'Uploading': return DocumentStatus.uploading;
    case 'Processing': return DocumentStatus.processing;
    case 'UnderReview': return DocumentStatus.underReview;
    case 'Approved': return DocumentStatus.approved;
    case 'Rejected': return DocumentStatus.rejected;
    case 'NeedsRevision': return DocumentStatus.needsRevision;
    case 'Archived': return DocumentStatus.archived;
    default: return DocumentStatus.removed;
  }
}
