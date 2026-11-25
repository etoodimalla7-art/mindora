/// Admin CMS + Broadcast API client (Phase 5).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

// ---------- DTOs ----------

class ContentString {
  const ContentString({
    required this.id,
    required this.key,
    this.description,
    required this.valueFr,
    required this.valueEn,
    required this.group,
    required this.updatedAt,
    required this.createdAt,
  });

  final String id;
  final String key;
  final String? description;
  final String valueFr;
  final String valueEn;
  final String group;
  final DateTime updatedAt;
  final DateTime createdAt;

  factory ContentString.fromJson(Map<String, dynamic> j) => ContentString(
        id: j['id'] as String,
        key: j['key'] as String,
        description: j['description'] as String?,
        valueFr: j['value_fr'] as String? ?? '',
        valueEn: j['value_en'] as String? ?? '',
        group: j['group'] as String? ?? 'general',
        updatedAt: DateTime.parse(j['updated_at'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class BroadcastItem {
  const BroadcastItem({
    required this.id,
    required this.title,
    required this.body,
    required this.targetCriteria,
    this.scheduledAt,
    this.sentAt,
    required this.sentCount,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> targetCriteria;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int sentCount;
  final DateTime createdAt;

  bool get isPending => sentAt == null;

  factory BroadcastItem.fromJson(Map<String, dynamic> j) => BroadcastItem(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        targetCriteria: Map<String, dynamic>.from(j['target_criteria'] as Map? ?? {}),
        scheduledAt: j['scheduled_at'] != null
            ? DateTime.tryParse(j['scheduled_at'] as String)
            : null,
        sentAt: j['sent_at'] != null
            ? DateTime.tryParse(j['sent_at'] as String)
            : null,
        sentCount: (j['sent_count'] as int?) ?? 0,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

// ---------- Repository ----------

class AdminContentRepository {
  AdminContentRepository(this._dio);
  final Dio _dio;

  // ----- Content -----

  Future<List<ContentString>> listContent({String? group}) async {
    final r = await _dio.get(
      '/admin/content',
      queryParameters: group != null ? {'group': group} : null,
    );
    return (r.data as List)
        .map((e) => ContentString.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ContentString> updateContent(
    String key, {
    String? valueFr,
    String? valueEn,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (valueFr != null) body['value_fr'] = valueFr;
    if (valueEn != null) body['value_en'] = valueEn;
    if (description != null) body['description'] = description;
    final r = await _dio.patch('/admin/content/$key', data: body);
    return ContentString.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ContentString> createContent({
    required String key,
    String valueFr = '',
    String valueEn = '',
    String group = 'general',
    String? description,
  }) async {
    final body = <String, dynamic>{
      'key': key,
      'value_fr': valueFr,
      'value_en': valueEn,
      'group': group,
    };
    if (description != null) body['description'] = description;
    final r = await _dio.post('/admin/content', data: body);
    return ContentString.fromJson(r.data as Map<String, dynamic>);
  }

  // ----- Broadcasts -----

  Future<List<BroadcastItem>> listBroadcasts() async {
    final r = await _dio.get('/admin/broadcasts');
    return (r.data as List)
        .map((e) => BroadcastItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BroadcastItem> createBroadcast({
    required String title,
    required String body,
    Map<String, dynamic> targetCriteria = const {},
    DateTime? scheduledAt,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'body': body,
      'target_criteria': targetCriteria,
    };
    if (scheduledAt != null) {
      payload['scheduled_at'] = scheduledAt.toUtc().toIso8601String();
    }
    final r = await _dio.post('/admin/broadcasts', data: payload);
    return BroadcastItem.fromJson(r.data as Map<String, dynamic>);
  }
}

// ---------- Riverpod ----------

final adminContentRepositoryProvider = Provider<AdminContentRepository>(
  (ref) => AdminContentRepository(ref.watch(dioProvider)),
);

final contentListProvider = FutureProvider<List<ContentString>>((ref) async {
  return ref.watch(adminContentRepositoryProvider).listContent();
});

final broadcastsListProvider = FutureProvider<List<BroadcastItem>>((ref) async {
  return ref.watch(adminContentRepositoryProvider).listBroadcasts();
});
