/// Admin Settings API client (Phase 7.2).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

// ---------- DTOs ----------

class Tagline {
  const Tagline({required this.fr, required this.en});
  final String fr;
  final String en;

  factory Tagline.fromJson(Map<String, dynamic>? j) => Tagline(
        fr: (j?['fr'] as String?) ?? '',
        en: (j?['en'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {'fr': fr, 'en': en};
}

class IdentitySettings {
  const IdentitySettings({
    required this.name,
    required this.tagline,
    required this.logoUrl,
    required this.primaryColor,
  });

  final String name;
  final Tagline tagline;
  final String logoUrl;
  final String primaryColor;

  factory IdentitySettings.fromJson(Map<String, dynamic> j) => IdentitySettings(
        name: (j['name'] as String?) ?? 'MINDORA',
        tagline: Tagline.fromJson(j['tagline'] as Map<String, dynamic>?),
        logoUrl: (j['logo_url'] as String?) ?? '',
        primaryColor: (j['primary_color'] as String?) ?? '#6E8DFF',
      );
}

class LanguageSettings {
  const LanguageSettings({required this.defaultLang, required this.active});
  final String defaultLang;
  final List<String> active;

  factory LanguageSettings.fromJson(Map<String, dynamic> j) => LanguageSettings(
        defaultLang: (j['default'] as String?) ?? 'fr',
        active: (j['active'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
      );
}

class MaintenanceSettings {
  const MaintenanceSettings({
    required this.enabled,
    required this.message,
    this.eta,
  });

  final bool enabled;
  final String message;
  final DateTime? eta;

  factory MaintenanceSettings.fromJson(Map<String, dynamic> j) =>
      MaintenanceSettings(
        enabled: (j['enabled'] as bool?) ?? false,
        message: (j['message'] as String?) ?? '',
        eta: j['eta'] != null ? DateTime.parse(j['eta'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'message': message,
        'eta': eta?.toIso8601String(),
      };
}

class FeatureFlag {
  const FeatureFlag({
    required this.key,
    required this.enabled,
    this.description,
    this.updatedAt,
  });

  final String key;
  final bool enabled;
  final String? description;
  final DateTime? updatedAt;

  factory FeatureFlag.fromJson(Map<String, dynamic> j) => FeatureFlag(
        key: j['key'] as String,
        enabled: j['enabled'] as bool? ?? false,
        description: j['description'] as String?,
        updatedAt: j['updated_at'] != null
            ? DateTime.parse(j['updated_at'] as String)
            : null,
      );
}

class SettingsOptions {
  const SettingsOptions({
    required this.identity,
    required this.languages,
    required this.educationSystems,
    required this.subjects,
    required this.levels,
    required this.years,
    required this.maintenance,
    required this.featureFlags,
  });

  final IdentitySettings identity;
  final LanguageSettings languages;
  final List<String> educationSystems;
  final List<String> subjects;
  final List<String> levels;
  final List<int> years;
  final MaintenanceSettings maintenance;
  final List<FeatureFlag> featureFlags;

  factory SettingsOptions.fromJson(Map<String, dynamic> j) => SettingsOptions(
        identity: IdentitySettings.fromJson(
            j['identity'] as Map<String, dynamic>? ?? {}),
        languages: LanguageSettings.fromJson(
            j['languages'] as Map<String, dynamic>? ?? {}),
        educationSystems: (j['education_systems'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        subjects: (j['subjects'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        levels: (j['levels'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        years: (j['years'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        maintenance: MaintenanceSettings.fromJson(
            j['maintenance'] as Map<String, dynamic>? ?? {}),
        featureFlags: (j['feature_flags'] as List<dynamic>? ?? [])
            .map((e) => FeatureFlag.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ---------- Repository ----------

class AdminSettingsRepository {
  AdminSettingsRepository(this._dio);
  final Dio _dio;

  Future<SettingsOptions> getOptions() async {
    final r = await _dio.get<Map<String, dynamic>>('/admin/settings/options');
    return SettingsOptions.fromJson(r.data!);
  }

  Future<void> updateSetting(String key, dynamic value) async {
    await _dio.patch<void>(
      '/admin/settings/$key',
      data: {'value': value},
    );
  }

  Future<void> updateFeatureFlag(String key, bool enabled) async {
    await _dio.patch<void>(
      '/admin/settings/feature-flags/$key',
      data: {'enabled': enabled},
    );
  }

  Future<MaintenanceSettings> setMaintenance(MaintenanceSettings payload) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/admin/settings/maintenance',
      data: payload.toJson(),
    );
    return MaintenanceSettings.fromJson(r.data!);
  }
}

// ---------- Providers ----------

final adminSettingsRepositoryProvider = Provider<AdminSettingsRepository>(
  (ref) => AdminSettingsRepository(ref.watch(dioProvider)),
);

final settingsOptionsProvider = FutureProvider<SettingsOptions>((ref) async {
  return ref.watch(adminSettingsRepositoryProvider).getOptions();
});
