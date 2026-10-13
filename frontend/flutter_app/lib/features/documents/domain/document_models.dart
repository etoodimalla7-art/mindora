import 'package:equatable/equatable.dart';

class DocumentAnalysis extends Equatable {
  const DocumentAnalysis({
    this.detectedLanguage,
    this.languageConfidence = 0,
    this.detectedSubject,
    this.subjectConfidence = 0,
    this.detectedLevel,
    this.levelConfidence = 0,
    this.detectedDocType,
    this.docTypeConfidence = 0,
    this.isSpam = false,
    this.isInappropriate = false,
    this.containsPii = false,
    this.qualityScore = 0,
    this.keywords = const [],
    this.summary,
  });

  final String? detectedLanguage;
  final double languageConfidence;
  final String? detectedSubject;
  final double subjectConfidence;
  final String? detectedLevel;
  final double levelConfidence;
  final String? detectedDocType;
  final double docTypeConfidence;
  final bool isSpam;
  final bool isInappropriate;
  final bool containsPii;
  final double qualityScore;
  final List<String> keywords;
  final String? summary;

  factory DocumentAnalysis.fromJson(Map<String, dynamic> j) => DocumentAnalysis(
        detectedLanguage: j['detected_language'] as String?,
        languageConfidence: (j['language_confidence'] as num?)?.toDouble() ?? 0,
        detectedSubject: j['detected_subject'] as String?,
        subjectConfidence: (j['subject_confidence'] as num?)?.toDouble() ?? 0,
        detectedLevel: j['detected_level'] as String?,
        levelConfidence: (j['level_confidence'] as num?)?.toDouble() ?? 0,
        detectedDocType: j['detected_doc_type'] as String?,
        docTypeConfidence: (j['doc_type_confidence'] as num?)?.toDouble() ?? 0,
        isSpam: j['is_spam'] as bool? ?? false,
        isInappropriate: j['is_inappropriate'] as bool? ?? false,
        containsPii: j['contains_pii'] as bool? ?? false,
        qualityScore: (j['quality_score'] as num?)?.toDouble() ?? 0,
        keywords: ((j['keywords'] as List?) ?? []).map((e) => e.toString()).toList(),
        summary: j['summary'] as String?,
      );

  @override
  List<Object?> get props => [detectedLanguage, detectedSubject, qualityScore];
}

class Document extends Equatable {
  const Document({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    this.category,
    this.academicLevel,
    required this.language,
    required this.isExamRelated,
    this.examSystem,
    this.examName,
    this.examYear,
    this.examSession,
    this.documentType,
    required this.originalFilename,
    required this.mimeType,
    required this.sizeBytes,
    this.pageCount,
    required this.status,
    this.rejectionReason,
    required this.downloadCount,
    required this.qualityScore,
    required this.createdAt,
    required this.updatedAt,
    this.analysis,
  });

  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String? category;
  final String? academicLevel;
  final String language;
  final bool isExamRelated;
  final String? examSystem;
  final String? examName;
  final int? examYear;
  final String? examSession;
  final String? documentType;
  final String originalFilename;
  final String mimeType;
  final int sizeBytes;
  final int? pageCount;
  final String status;
  final String? rejectionReason;
  final int downloadCount;
  final double qualityScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DocumentAnalysis? analysis;

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isUnderReview => status == 'under_review';
  bool get isUploading => status == 'uploading';

  factory Document.fromJson(Map<String, dynamic> j) => Document(
        id: j['id'] as String,
        ownerId: j['owner_id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        category: j['category'] as String?,
        academicLevel: j['academic_level'] as String?,
        language: j['language'] as String,
        isExamRelated: j['is_exam_related'] as bool? ?? false,
        examSystem: j['exam_system'] as String?,
        examName: j['exam_name'] as String?,
        examYear: j['exam_year'] as int?,
        examSession: j['exam_session'] as String?,
        documentType: j['document_type'] as String?,
        originalFilename: j['original_filename'] as String,
        mimeType: j['mime_type'] as String,
        sizeBytes: j['size_bytes'] as int,
        pageCount: j['page_count'] as int?,
        status: j['status'] as String,
        rejectionReason: j['rejection_reason'] as String?,
        downloadCount: j['download_count'] as int? ?? 0,
        qualityScore: (j['quality_score'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        analysis: j['analysis'] != null
            ? DocumentAnalysis.fromJson(j['analysis'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [id, status, updatedAt];
}

class DocumentStatus extends Equatable {
  const DocumentStatus({
    required this.id,
    required this.status,
    required this.steps,
    this.rejectionReason,
  });

  final String id;
  final String status;
  final Map<String, String> steps;
  final String? rejectionReason;

  factory DocumentStatus.fromJson(Map<String, dynamic> j) => DocumentStatus(
        id: j['id'] as String,
        status: j['status'] as String,
        steps: ((j['steps'] as Map?) ?? {})
            .map((k, v) => MapEntry(k.toString(), v.toString())),
        rejectionReason: j['rejection_reason'] as String?,
      );

  @override
  List<Object?> get props => [id, status];
}

class CreditBalance extends Equatable {
  const CreditBalance({
    required this.balance,
    required this.signupBonus,
    required this.contributionReward,
    required this.downloadCost,
    required this.history,
  });

  final int balance;
  final int signupBonus;
  final int contributionReward;
  final int downloadCost;
  final List<CreditEntry> history;

  factory CreditBalance.fromJson(Map<String, dynamic> j) => CreditBalance(
        balance: j['balance'] as int,
        signupBonus: j['signup_bonus'] as int,
        contributionReward: j['contribution_reward'] as int,
        downloadCost: j['download_cost'] as int,
        history: ((j['history'] as List?) ?? [])
            .map((e) => CreditEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [balance];
}

class CreditEntry extends Equatable {
  const CreditEntry({
    required this.id,
    required this.delta,
    required this.reason,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final int delta;
  final String reason;
  final String? notes;
  final DateTime createdAt;

  factory CreditEntry.fromJson(Map<String, dynamic> j) => CreditEntry(
        id: j['id'] as String,
        delta: j['delta'] as int,
        reason: j['reason'] as String,
        notes: j['notes'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  @override
  List<Object?> get props => [id];
}
