/// Admin AI Control Center API client (Phase 4).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

// ---------- DTOs ----------

class AIConfig {
  const AIConfig({
    required this.id,
    required this.name,
    required this.systemPrompt,
    required this.model,
    required this.temperature,
    required this.maxTokens,
    required this.language,
    required this.isActive,
    required this.updatedAt,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String systemPrompt;
  final String model;
  final double temperature;
  final int maxTokens;
  final String language;
  final bool isActive;
  final DateTime updatedAt;
  final DateTime createdAt;

  factory AIConfig.fromJson(Map<String, dynamic> j) => AIConfig(
        id: j['id'] as String,
        name: j['name'] as String,
        systemPrompt: j['system_prompt'] as String,
        model: j['model'] as String,
        temperature: (j['temperature'] as num).toDouble(),
        maxTokens: j['max_tokens'] as int,
        language: j['language'] as String,
        isActive: j['is_active'] as bool? ?? true,
        updatedAt: DateTime.parse(j['updated_at'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class AIConfigVersion {
  const AIConfigVersion({
    required this.id,
    required this.configId,
    required this.version,
    required this.systemPrompt,
    required this.model,
    required this.temperature,
    required this.maxTokens,
    this.notes,
    this.publishedBy,
    required this.publishedAt,
  });

  final String id;
  final String configId;
  final int version;
  final String systemPrompt;
  final String model;
  final double temperature;
  final int maxTokens;
  final String? notes;
  final String? publishedBy;
  final DateTime publishedAt;

  factory AIConfigVersion.fromJson(Map<String, dynamic> j) => AIConfigVersion(
        id: j['id'] as String,
        configId: j['config_id'] as String,
        version: j['version'] as int,
        systemPrompt: j['system_prompt'] as String,
        model: j['model'] as String,
        temperature: (j['temperature'] as num).toDouble(),
        maxTokens: j['max_tokens'] as int,
        notes: j['notes'] as String?,
        publishedBy: j['published_by'] as String?,
        publishedAt: DateTime.parse(j['published_at'] as String),
      );
}

class AITestResult {
  const AITestResult({
    required this.response,
    required this.model,
    required this.provider,
    required this.usage,
    required this.elapsedMs,
  });

  final String response;
  final String model;
  final String provider;
  final Map<String, dynamic> usage;
  final int elapsedMs;

  factory AITestResult.fromJson(Map<String, dynamic> j) => AITestResult(
        response: j['response'] as String,
        model: j['model'] as String,
        provider: j['provider'] as String,
        usage: Map<String, dynamic>.from(j['usage'] as Map? ?? {}),
        elapsedMs: (j['elapsed_ms'] as int?) ?? 0,
      );
}

// ---------- Repository ----------

class AdminAIRepository {
  AdminAIRepository(this._dio);
  final Dio _dio;

  Future<AIConfig> getConfig() async {
    final r = await _dio.get('/admin/ai/config');
    return AIConfig.fromJson(r.data as Map<String, dynamic>);
  }

  Future<AIConfig> updateConfig({
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
    String? language,
  }) async {
    final body = <String, dynamic>{};
    if (systemPrompt != null) body['system_prompt'] = systemPrompt;
    if (model != null) body['model'] = model;
    if (temperature != null) body['temperature'] = temperature;
    if (maxTokens != null) body['max_tokens'] = maxTokens;
    if (language != null) body['language'] = language;

    final r = await _dio.patch('/admin/ai/config', data: body);
    return AIConfig.fromJson(r.data as Map<String, dynamic>);
  }

  Future<AIConfigVersion> publish({String? notes}) async {
    final r = await _dio.post(
      '/admin/ai/config/publish',
      data: {'notes': notes},
    );
    return AIConfigVersion.fromJson(r.data as Map<String, dynamic>);
  }

  Future<AITestResult> test({
    required String message,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    final body = <String, dynamic>{'message': message};
    if (systemPrompt != null) body['system_prompt'] = systemPrompt;
    if (model != null) body['model'] = model;
    if (temperature != null) body['temperature'] = temperature;
    if (maxTokens != null) body['max_tokens'] = maxTokens;

    final r = await _dio.post(
      '/admin/ai/config/test',
      data: body,
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    return AITestResult.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<AIConfigVersion>> listVersions() async {
    final r = await _dio.get('/admin/ai/versions');
    return (r.data as List)
        .map((e) => AIConfigVersion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AIConfig> activateVersion(String versionId) async {
    final r = await _dio.post('/admin/ai/versions/$versionId/activate');
    return AIConfig.fromJson(r.data as Map<String, dynamic>);
  }
}

// ---------- Riverpod ----------

final adminAIRepositoryProvider = Provider<AdminAIRepository>(
  (ref) => AdminAIRepository(ref.watch(dioProvider)),
);

final aiConfigProvider = FutureProvider<AIConfig>((ref) async {
  return ref.watch(adminAIRepositoryProvider).getConfig();
});

final aiVersionsProvider = FutureProvider<List<AIConfigVersion>>((ref) async {
  return ref.watch(adminAIRepositoryProvider).listVersions();
});
