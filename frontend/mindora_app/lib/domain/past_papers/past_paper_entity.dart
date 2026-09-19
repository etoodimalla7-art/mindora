class PastPaperEntity {
  const PastPaperEntity({
    required this.id,
    required this.title,
    required this.level,
    required this.year,
    this.session,
    required this.subjectName,
    required this.examinationName,
    required this.country,
    required this.system,
    required this.isBookmarked,
  });

  final String id;
  final String title;
  final String level;
  final int year;
  final String? session;
  final String subjectName;
  final String examinationName;
  final String country;
  final String system;
  final bool isBookmarked;

  factory PastPaperEntity.fromJson(Map<String, dynamic> json) => PastPaperEntity(
        id: json['id'] as String,
        title: json['title'] as String,
        level: json['level'] as String,
        year: json['year'] as int,
        session: json['session'] as String?,
        subjectName: json['subject_name'] as String,
        examinationName: json['examination_name'] as String,
        country: json['country'] as String,
        system: json['system'] as String,
        isBookmarked: json['is_bookmarked'] as bool? ?? false,
      );

  PastPaperEntity copyWith({bool? isBookmarked}) => PastPaperEntity(
        id: id, title: title, level: level, year: year, session: session,
        subjectName: subjectName, examinationName: examinationName,
        country: country, system: system,
        isBookmarked: isBookmarked ?? this.isBookmarked,
      );
}

class PastPaperFilters {
  const PastPaperFilters({
    required this.countries,
    required this.systems,
    required this.levels,
    required this.subjects,
    required this.years,
  });

  final List<String> countries;
  final List<String> systems;
  final List<String> levels;
  final List<String> subjects;
  final List<int> years;

  factory PastPaperFilters.fromJson(Map<String, dynamic> json) => PastPaperFilters(
        countries: (json['countries'] as List).cast<String>(),
        systems: (json['systems'] as List).cast<String>(),
        levels: (json['levels'] as List).cast<String>(),
        subjects: (json['subjects'] as List).cast<String>(),
        years: (json['years'] as List).cast<int>(),
      );
}

/// Section 30's hierarchy — held together so the browse screen can drive
/// cascading dropdowns without five separate pieces of state.
class PastPaperFilterSelection {
  const PastPaperFilterSelection({
    this.country, this.system, this.level, this.subject, this.year, this.query,
  });

  final String? country;
  final String? system;
  final String? level;
  final String? subject;
  final int? year;
  final String? query;

  bool get isEmpty =>
      country == null && system == null && level == null && subject == null && year == null &&
      (query == null || query!.isEmpty);

  PastPaperFilterSelection copyWith({
    String? country, bool clearCountry = false,
    String? system, bool clearSystem = false,
    String? level, bool clearLevel = false,
    String? subject, bool clearSubject = false,
    int? year, bool clearYear = false,
    String? query,
  }) {
    return PastPaperFilterSelection(
      country: clearCountry ? null : (country ?? this.country),
      system: clearSystem ? null : (system ?? this.system),
      level: clearLevel ? null : (level ?? this.level),
      subject: clearSubject ? null : (subject ?? this.subject),
      year: clearYear ? null : (year ?? this.year),
      query: query ?? this.query,
    );
  }
}
