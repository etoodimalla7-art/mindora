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

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    required this.preferredLanguage,
    required this.countryCode,
    this.isAdmin = false,
  });

  final String id;
  final String email;
  final String? fullName;
  final String preferredLanguage;
  final String countryCode;
  final bool isAdmin;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        preferredLanguage: (json['preferred_language'] as String?) ?? 'en',
        countryCode: (json['country_code'] as String?) ?? 'CM',
        isAdmin: (json['is_admin'] as bool?) ?? false,
      );

  @override
  List<Object?> get props =>
      [id, email, fullName, preferredLanguage, countryCode, isAdmin];
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
