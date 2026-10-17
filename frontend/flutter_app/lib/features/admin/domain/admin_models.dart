/// Admin DTOs — legacy (moderation) + new (stats, users, papers).
library;

// ============================================================
// LEGACY — Documents moderation (existing screens rely on these)
// ============================================================

class AdminDocumentRow {
  final String id;
  final String title;
  final String? description;
  final String? ownerEmail;
  final String? status;
  final String? category;
  final String? academicLevel;
  final String? language;
  final int? sizeBytes;
  final double? qualityScore;
  final String? rejectionReason;
  final DateTime createdAt;

  AdminDocumentRow({
    required this.id,
    required this.title,
    this.description,
    this.ownerEmail,
    this.status,
    this.category,
    this.academicLevel,
    this.language,
    this.sizeBytes,
    this.qualityScore,
    this.rejectionReason,
    required this.createdAt,
  });

  factory AdminDocumentRow.fromJson(Map<String, dynamic> j) => AdminDocumentRow(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        ownerEmail: j['owner_email'] as String?,
        status: j['status'] as String?,
        category: j['category'] as String?,
        academicLevel: j['academic_level'] as String?,
        language: j['language'] as String?,
        sizeBytes: j['size_bytes'] as int?,
        qualityScore: (j['quality_score'] as num?)?.toDouble(),
        rejectionReason: j['rejection_reason'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.parse(j['created_at'] as String)
            : DateTime.now(),
      );
}

class ApproveResult {
  final String id;
  final String status;
  ApproveResult({required this.id, required this.status});
  factory ApproveResult.fromJson(Map<String, dynamic> j) =>
      ApproveResult(id: j['id'] as String, status: j['status'] as String);
}

class RejectResult {
  final String id;
  final String status;
  final String reason;
  RejectResult({required this.id, required this.status, required this.reason});
  factory RejectResult.fromJson(Map<String, dynamic> j) => RejectResult(
        id: j['id'] as String,
        status: j['status'] as String,
        reason: j['reason'] as String,
      );
}

// ============================================================
// NEW — Stats, Users, Papers
// ============================================================

class AdminStats {
  final UsersStats users;
  final DocumentsStats documents;
  final PapersStats papers;
  final ActivityStats activity;

  AdminStats({
    required this.users,
    required this.documents,
    required this.papers,
    required this.activity,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        users: UsersStats.fromJson(j['users'] as Map<String, dynamic>),
        documents: DocumentsStats.fromJson(j['documents'] as Map<String, dynamic>),
        papers: PapersStats.fromJson(j['papers'] as Map<String, dynamic>),
        activity: ActivityStats.fromJson(j['activity'] as Map<String, dynamic>),
      );
}

class UsersStats {
  final int total, active, admins, newThisWeek;
  UsersStats({required this.total, required this.active, required this.admins, required this.newThisWeek});
  factory UsersStats.fromJson(Map<String, dynamic> j) => UsersStats(
        total: j['total'] as int,
        active: j['active'] as int,
        admins: j['admins'] as int,
        newThisWeek: j['new_this_week'] as int,
      );
}

class DocumentsStats {
  final int total, pending, approved;
  DocumentsStats({required this.total, required this.pending, required this.approved});
  factory DocumentsStats.fromJson(Map<String, dynamic> j) => DocumentsStats(
        total: j['total'] as int,
        pending: j['pending'] as int,
        approved: j['approved'] as int,
      );
}

class PapersStats {
  final int total, published, draft;
  PapersStats({required this.total, required this.published, required this.draft});
  factory PapersStats.fromJson(Map<String, dynamic> j) => PapersStats(
        total: j['total'] as int,
        published: j['published'] as int,
        draft: j['draft'] as int,
      );
}

class ActivityStats {
  final int sessionsToday, uploadsToday;
  ActivityStats({required this.sessionsToday, required this.uploadsToday});
  factory ActivityStats.fromJson(Map<String, dynamic> j) => ActivityStats(
        sessionsToday: j['sessions_today'] as int,
        uploadsToday: j['uploads_today'] as int,
      );
}

class AdminUser {
  final String id;
  final String email;
  final String? fullName;
  final bool isActive, isVerified, isAdmin;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  AdminUser({
    required this.id,
    required this.email,
    this.fullName,
    required this.isActive,
    required this.isVerified,
    required this.isAdmin,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: j['id'] as String,
        email: j['email'] as String,
        fullName: j['full_name'] as String?,
        isActive: j['is_active'] as bool,
        isVerified: j['is_verified'] as bool,
        isAdmin: j['is_admin'] as bool,
        createdAt: DateTime.parse(j['created_at'] as String),
        lastLoginAt: j['last_login_at'] != null ? DateTime.parse(j['last_login_at'] as String) : null,
      );
}

class AdminPaper {
  final String id;
  final String title;
  final String subject;
  final String examSystem;
  final String examLevel;
  final int? examYear;
  final String language;
  final String status;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final int downloadCount;
  final DateTime createdAt;

  AdminPaper({
    required this.id,
    required this.title,
    required this.subject,
    required this.examSystem,
    required this.examLevel,
    this.examYear,
    required this.language,
    required this.status,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.downloadCount,
    required this.createdAt,
  });

  factory AdminPaper.fromJson(Map<String, dynamic> j) => AdminPaper(
        id: j['id'] as String,
        title: j['title'] as String,
        subject: j['subject'] as String,
        examSystem: j['exam_system'] as String,
        examLevel: j['exam_level'] as String,
        examYear: j['exam_year'] as int?,
        language: j['language'] as String,
        status: j['status'] as String,
        fileName: j['file_name'] as String,
        fileSize: j['file_size'] as int,
        mimeType: j['mime_type'] as String,
        downloadCount: j['download_count'] as int,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
