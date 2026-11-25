class Paper {
  final String id;
  final String title;
  final String subject;
  final String examSystem;
  final String examLevel;
  final int? examYear;
  final String language;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final int downloadCount;

  Paper({
    required this.id,
    required this.title,
    required this.subject,
    required this.examSystem,
    required this.examLevel,
    this.examYear,
    required this.language,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.downloadCount,
  });

  factory Paper.fromJson(Map<String, dynamic> j) => Paper(
        id: j['id'],
        title: j['title'],
        subject: j['subject'],
        examSystem: j['exam_system'],
        examLevel: j['exam_level'],
        examYear: j['exam_year'],
        language: j['language'],
        fileName: j['file_name'],
        fileSize: j['file_size'],
        mimeType: j['mime_type'],
        downloadCount: j['download_count'] ?? 0,
      );
}
