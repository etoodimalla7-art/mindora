/// Admin Documents API client (Phase 3).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class AdminDocumentDetail {
  const AdminDocumentDetail({
    required this.id,
    required this.title,
    this.description,
    required this.ownerEmail,
    this.ownerId,
    this.category,
    this.academicLevel,
    required this.language,
    this.examSystem,
    this.examName,
    this.examYear,
    this.documentType,
    required this.sizeBytes,
    this.pageCount,
    required this.status,
    this.rejectionReason,
    this.moderationNotes,
    required this.qualityScore,
    required this.downloadCount,
    required this.originalFilename,
    required this.mimeType,
    this.archivedAt,
    this.archivedBy,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String ownerEmail;
  final String? ownerId;
  final String? category;
  final String? academicLevel;
  final String language;
  final String? examSystem;
  final String? examName;
  final int? examYear;
  final String? documentType;
  final int sizeBytes;
  final int? pageCount;
  final String status;
  final String? rejectionReason;
  final String? moderationNotes;
  final double qualityScore;
  final int downloadCount;
  final String originalFilename;
  final String mimeType;
  final DateTime? archivedAt;
  final String? archivedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isArchived => archivedAt != null;
  bool get isPending => status == 'under_review';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isUploading => status == 'uploading';

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  factory AdminDocumentDetail.fromJson(Map<String, dynamic> j) =>
      AdminDocumentDetail(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        ownerEmail: j['owner_email'] as String? ?? '',
        ownerId: j['owner_id'] as String?,
        category: j['category'] as String?,
        academicLevel: j['academic_level'] as String?,
        language: j['language'] as String? ?? 'en',
        examSystem: j['exam_system'] as String?,
        examName: j['exam_name'] as String?,
        examYear: j['exam_year'] as int?,
        documentType: j['document_type'] as String?,
        sizeBytes: (j['size_bytes'] as int?) ?? 0,
        pageCount: j['page_count'] as int?,
        status: j['status'] as String? ?? 'under_review',
        rejectionReason: j['rejection_reason'] as String?,
        moderationNotes: j['moderation_notes'] as String?,
        qualityScore: (j['quality_score'] as num?)?.toDouble() ?? 0.0,
        downloadCount: (j['download_count'] as int?) ?? 0,
        originalFilename: j['original_filename'] as String? ?? '',
        mimeType: j['mime_type'] as String? ?? 'application/pdf',
        archivedAt: j['archived_at'] != null
            ? DateTime.tryParse(j['archived_at'] as String)
            : null,
        archivedBy: j['archived_by'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: j['updated_at'] != null
            ? DateTime.tryParse(j['updated_at'] as String)
            : null,
      );
}

class DocumentsFilter {
  const DocumentsFilter({
    this.status,
    this.category,
    this.academicLevel,
    this.language,
    this.examSystem,
    this.search,
    this.archived = false,
    this.sort = 'recent',
  });

  final String? status;
  final String? category;
  final String? academicLevel;
  final String? language;
  final String? examSystem;
  final String? search;
  final bool archived;
  final String sort;

  DocumentsFilter copyWith({
    String? status,
    String? category,
    String? academicLevel,
    String? language,
    String? examSystem,
    String? search,
    bool? archived,
    String? sort,
    bool clearStatus = false,
    bool clearCategory = false,
    bool clearLevel = false,
    bool clearLanguage = false,
    bool clearExamSystem = false,
    bool clearSearch = false,
  }) =>
      DocumentsFilter(
        status: clearStatus ? null : (status ?? this.status),
        category: clearCategory ? null : (category ?? this.category),
        academicLevel: clearLevel ? null : (academicLevel ?? this.academicLevel),
        language: clearLanguage ? null : (language ?? this.language),
        examSystem: clearExamSystem ? null : (examSystem ?? this.examSystem),
        search: clearSearch ? null : (search ?? this.search),
        archived: archived ?? this.archived,
        sort: sort ?? this.sort,
      );
}

class AdminDocumentsRepository {
  AdminDocumentsRepository(this._dio);
  final Dio _dio;

  Future<List<AdminDocumentDetail>> list(DocumentsFilter f) async {
    final params = <String, dynamic>{
      'archived': f.archived,
      'sort': f.sort,
      'limit': 100,
    };
    if (f.status != null) params['status'] = f.status;
    if (f.category != null) params['category'] = f.category;
    if (f.academicLevel != null) params['academic_level'] = f.academicLevel;
    if (f.language != null) params['language'] = f.language;
    if (f.examSystem != null) params['exam_system'] = f.examSystem;
    if (f.search != null) params['search'] = f.search;

    final r = await _dio.get('/admin/documents', queryParameters: params);
    return (r.data as List)
        .map((e) => AdminDocumentDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approve(String docId) async {
    await _dio.post('/admin/documents/$docId/approve');
  }

  Future<void> reject(String docId, String reason) async {
    await _dio.post(
      '/admin/documents/$docId/reject',
      data: {'reason': reason},
    );
  }

  Future<Map<String, dynamic>> archive(String docId) async {
    final r = await _dio.post('/admin/documents/$docId/archive');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unarchive(String docId) async {
    final r = await _dio.post('/admin/documents/$docId/unarchive');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bulkApprove(List<String> ids) async {
    final r = await _dio.post(
      '/admin/documents/bulk-approve',
      data: {'document_ids': ids},
    );
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bulkReject(List<String> ids, String reason) async {
    final r = await _dio.post(
      '/admin/documents/bulk-reject',
      data: {'document_ids': ids, 'reason': reason},
    );
    return r.data as Map<String, dynamic>;
  }

  String downloadUrl(String docId) {
    return '${_dio.options.baseUrl}/admin/documents/$docId/download';
  }
}

// ---------- Riverpod ----------

final adminDocumentsRepositoryProvider = Provider<AdminDocumentsRepository>(
  (ref) => AdminDocumentsRepository(ref.watch(dioProvider)),
);

final documentsFilterProvider =
    StateProvider<DocumentsFilter>((_) => const DocumentsFilter());

final adminDocumentsProvider =
    FutureProvider<List<AdminDocumentDetail>>((ref) async {
  final f = ref.watch(documentsFilterProvider);
  return ref.watch(adminDocumentsRepositoryProvider).list(f);
});
