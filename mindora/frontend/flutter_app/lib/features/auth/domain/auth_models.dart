import 'package:equatable/equatable.dart';

class AuthTokens extends Equatable {
  const AuthTokens({required this.accessToken, required this.refreshToken});
  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
      };

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

/// Mirrors backend EducationProfile (subset used by client).
class EducationProfile extends Equatable {
  const EducationProfile({
    this.educationSystem,
    this.level,
    this.program,
    this.subjects = const [],
    this.goals = const [],
    this.targetExamDate,
  });

  final String? educationSystem;
  final String? level;
  final String? program;
  final List<String> subjects;
  final List<String> goals;
  final DateTime? targetExamDate;

  /// Profile is "completed" if the user picked a system + level.
  bool get isCompleted {
    return educationSystem != null &&
        educationSystem!.isNotEmpty &&
        level != null &&
        level!.isNotEmpty;
  }

  factory EducationProfile.fromJson(Map<String, dynamic> json) => EducationProfile(
        educationSystem: json['education_system'] as String?,
        level: json['level'] as String?,
        program: json['program'] as String?,
        subjects: (json['subjects'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        goals: (json['goals'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        targetExamDate: json['target_exam_date'] != null
            ? DateTime.tryParse(json['target_exam_date'].toString())
            : null,
      );

  @override
  List<Object?> get props => [
        educationSystem,
        level,
        program,
        subjects,
        goals,
        targetExamDate,
      ];
}

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    required this.preferredLanguage,
    required this.countryCode,
    this.isAdmin = false,
    this.isVerified = false,
    this.educationProfile,
  });

  final String id;
  final String email;
  final String? fullName;
  final String preferredLanguage;
  final String countryCode;
  final bool isAdmin;
  final bool isVerified;
  final EducationProfile? educationProfile;

  /// True if the user has completed onboarding (education profile filled).
  bool get hasCompletedOnboarding =>
      educationProfile != null && educationProfile!.isCompleted;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        preferredLanguage: (json['preferred_language'] as String?) ?? 'en',
        countryCode: (json['country_code'] as String?) ?? 'CM',
        isAdmin: (json['is_admin'] as bool?) ?? false,
        isVerified: (json['is_verified'] as bool?) ?? false,
        educationProfile: json['education_profile'] != null
            ? EducationProfile.fromJson(
                json['education_profile'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        preferredLanguage,
        countryCode,
        isAdmin,
        isVerified,
        educationProfile,
      ];
}

class AuthSession extends Equatable {
  const AuthSession({required this.tokens, required this.user});
  final AuthTokens tokens;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [tokens, user];
}
