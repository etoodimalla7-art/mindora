class CurrentUserEntity {
  const CurrentUserEntity({required this.id, required this.email, required this.locale, required this.role});
  final String id;
  final String email;
  final String locale;
  final String role;

  bool get isAdmin => role == 'admin';

  factory CurrentUserEntity.fromJson(Map<String, dynamic> json) => CurrentUserEntity(
        id: json['id'] as String,
        email: json['email'] as String,
        locale: json['locale'] as String,
        role: json['role'] as String,
      );
}
