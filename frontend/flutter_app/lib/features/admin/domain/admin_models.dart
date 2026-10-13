import 'package:equatable/equatable.dart';

class AdminDocumentRow extends Equatable {
  const AdminDocumentRow({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.originalFilename,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
    required this.qualityScore,
    this.category,
    this.academicLevel,
    required this.language,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String originalFilename;
  final String mimeType;
  final int sizeBytes;
  final String status;
  final double qualityScore;
  final String? category;
  final String? academicLevel;
  final String language;
  final DateTime createdAt;

  factory AdminDocumentRow.fromJson(Map<String, dynamic> j) => AdminDocumentRow(
        id: j['id'] as String,
        ownerId: j['owner_id'] as String,
        title: j['title'] as String,
        originalFilename: j['original_filename'] as String,
        mimeType: j['mime_type'] as String,
        sizeBytes: j['size_bytes'] as int,
        status: j['status'] as String,
        qualityScore: (j['quality_score'] as num?)?.toDouble() ?? 0,
        category: j['category'] as String?,
        academicLevel: j['academic_level'] as String?,
        language: j['language'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, status];
}

class ApproveResult extends Equatable {
  const ApproveResult({
    required this.documentId,
    required this.status,
    required this.contributorReward,
    required this.message,
  });

  final String documentId;
  final String status;
  final int contributorReward;
  final String message;

  factory ApproveResult.fromJson(Map<String, dynamic> j) => ApproveResult(
        documentId: j['document_id'] as String,
        status: j['status'] as String,
        contributorReward: j['contributor_reward'] as int,
        message: j['message'] as String,
      );

  @override
  List<Object?> get props => [documentId, status];
}

class RejectResult extends Equatable {
  const RejectResult({
    required this.documentId,
    required this.status,
    required this.reason,
    required this.message,
  });

  final String documentId;
  final String status;
  final String reason;
  final String message;

  factory RejectResult.fromJson(Map<String, dynamic> j) => RejectResult(
        documentId: j['document_id'] as String,
        status: j['status'] as String,
        reason: j['reason'] as String,
        message: j['message'] as String,
      );

  @override
  List<Object?> get props => [documentId, status];
}
