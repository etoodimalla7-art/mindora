/// Admin analytics API client + Riverpod providers.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:js_interop';
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_client.dart';

// ============================================================
// LEGACY DTOs — Phase 1 (dashboard)
// ============================================================

class AnalyticsOverview {
  AnalyticsOverview({
    required this.usersTotal,
    required this.usersNew7d,
    required this.usersActive24h,
    required this.docsTotal,
    required this.docsPending,
    required this.docsApproved,
    required this.docsRejected,
    required this.papersTotal,
    required this.papersPublished,
    required this.auditActions24h,
  });

  final int usersTotal;
  final int usersNew7d;
  final int usersActive24h;
  final int docsTotal;
  final int docsPending;
  final int docsApproved;
  final int docsRejected;
  final int papersTotal;
  final int papersPublished;
  final int auditActions24h;

  factory AnalyticsOverview.fromJson(Map<String, dynamic> j) {
    final u = j['users'] as Map<String, dynamic>;
    final d = j['documents'] as Map<String, dynamic>;
    final p = j['papers'] as Map<String, dynamic>;
    final a = j['activity'] as Map<String, dynamic>;
    return AnalyticsOverview(
      usersTotal: u['total'] as int? ?? 0,
      usersNew7d: u['new_7d'] as int? ?? 0,
      usersActive24h: u['active_24h'] as int? ?? 0,
      docsTotal: d['total'] as int? ?? 0,
      docsPending: d['pending'] as int? ?? 0,
      docsApproved: d['approved'] as int? ?? 0,
      docsRejected: d['rejected'] as int? ?? 0,
      papersTotal: p['total'] as int? ?? 0,
      papersPublished: p['published'] as int? ?? 0,
      auditActions24h: a['audit_actions_24h'] as int? ?? 0,
    );
  }
}

class TimePoint {
  TimePoint({required this.date, required this.count});
  final DateTime date;
  final int count;

  factory TimePoint.fromJson(Map<String, dynamic> j, {String countKey = 'count'}) =>
      TimePoint(
        date: DateTime.parse(j['date'] as String),
        count: j[countKey] as int? ?? 0,
      );
}

class BreakdownItem {
  BreakdownItem({required this.label, required this.count});
  final String label;
  final int count;

  factory BreakdownItem.fromJson(Map<String, dynamic> j, {String labelKey = 'subject'}) =>
      BreakdownItem(
        label: j[labelKey] as String? ?? '—',
        count: j['count'] as int? ?? 0,
      );
}

class RecentActivityItem {
  RecentActivityItem({
    required this.id,
    required this.action,
    this.resourceType,
    this.resourceId,
    this.adminEmail,
    this.result,
    required this.createdAt,
  });

  final String id;
  final String action;
  final String? resourceType;
  final String? resourceId;
  final String? adminEmail;
  final String? result;
  final DateTime createdAt;

  factory RecentActivityItem.fromJson(Map<String, dynamic> j) => RecentActivityItem(
        id: j['id'] as String,
        action: j['action'] as String,
        resourceType: j['resource_type'] as String?,
        resourceId: j['resource_id'] as String?,
        adminEmail: j['admin_email'] as String?,
        result: j['result'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

// ============================================================
// PHASE 6.1 DTOs — Advanced analytics
// ============================================================

class CohortRow {
  CohortRow({
    required this.cohortWeek,
    required this.cohortSize,
    required this.retention,
  });

  final String cohortWeek;
  final int cohortSize;
  final List<double> retention;

  factory CohortRow.fromJson(Map<String, dynamic> j) => CohortRow(
        cohortWeek: j['cohort_week'] as String,
        cohortSize: j['cohort_size'] as int? ?? 0,
        retention: (j['retention'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}

class RetentionResponse {
  RetentionResponse({required this.weeks, required this.cohorts});
  final int weeks;
  final List<CohortRow> cohorts;

  factory RetentionResponse.fromJson(Map<String, dynamic> j) => RetentionResponse(
        weeks: j['weeks'] as int? ?? 0,
        cohorts: (j['cohorts'] as List<dynamic>? ?? [])
            .map((e) => CohortRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FunnelStage {
  FunnelStage({
    required this.key,
    required this.label,
    required this.count,
    required this.conversionFromPrev,
    required this.conversionFromStart,
  });

  final String key;
  final String label;
  final int count;
  final double conversionFromPrev;
  final double conversionFromStart;

  factory FunnelStage.fromJson(Map<String, dynamic> j) => FunnelStage(
        key: j['key'] as String,
        label: j['label'] as String,
        count: j['count'] as int? ?? 0,
        conversionFromPrev: (j['conversion_from_prev'] as num? ?? 0).toDouble(),
        conversionFromStart: (j['conversion_from_start'] as num? ?? 0).toDouble(),
      );
}

class FunnelResponse {
  FunnelResponse({required this.days, required this.totalSignups, required this.stages});
  final int days;
  final int totalSignups;
  final List<FunnelStage> stages;

  factory FunnelResponse.fromJson(Map<String, dynamic> j) => FunnelResponse(
        days: j['days'] as int? ?? 0,
        totalSignups: j['total_signups'] as int? ?? 0,
        stages: (j['stages'] as List<dynamic>? ?? [])
            .map((e) => FunnelStage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ============================================================
// REPOSITORY
// ============================================================

class AdminAnalyticsRepository {
  AdminAnalyticsRepository(this._dio);
  final Dio _dio;

  // ---------- Phase 1 (existing) ----------

  Future<AnalyticsOverview> overview() async {
    final r = await _dio.get<Map<String, dynamic>>('/admin/analytics/overview');
    return AnalyticsOverview.fromJson(r.data!);
  }

  Future<List<TimePoint>> usersTimeseries({int days = 7}) async {
    final r = await _dio.get<List<dynamic>>(
      '/admin/analytics/users-timeseries',
      queryParameters: {'days': days},
    );
    return r.data!.map((e) => TimePoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TimePoint>> documentsTimeseries({int days = 7}) async {
    final r = await _dio.get<List<dynamic>>(
      '/admin/analytics/documents-timeseries',
      queryParameters: {'days': days},
    );
    return r.data!
        .map((e) => TimePoint.fromJson(e as Map<String, dynamic>, countKey: 'submitted'))
        .toList();
  }

  Future<List<BreakdownItem>> subjectsBreakdown() async {
    final r = await _dio.get<List<dynamic>>('/admin/analytics/subjects-breakdown');
    return r.data!.map((e) => BreakdownItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BreakdownItem>> examSystemsBreakdown() async {
    final r = await _dio.get<List<dynamic>>(
      '/admin/analytics/exam-systems-breakdown',
    );
    return r.data!
        .map((e) => BreakdownItem.fromJson(e as Map<String, dynamic>, labelKey: 'system'))
        .toList();
  }

  Future<List<RecentActivityItem>> recentActivity({int limit = 20}) async {
    final r = await _dio.get<List<dynamic>>(
      '/admin/analytics/recent-activity',
      queryParameters: {'limit': limit},
    );
    return r.data!
        .map((e) => RecentActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------- Phase 6.1 (new) ----------

  /// Weekly signup cohort retention curves.
  Future<RetentionResponse> retention({int weeks = 8}) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/admin/analytics/retention',
      queryParameters: {'weeks': weeks},
    );
    return RetentionResponse.fromJson(r.data!);
  }

  /// Engagement funnel (signup → verified → onboarding → chat → mock → paid).
  Future<FunnelResponse> funnel({int days = 30}) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/admin/analytics/funnel',
      queryParameters: {'days': days},
    );
    return FunnelResponse.fromJson(r.data!);
  }

  /// Download users CSV.
  ///
  /// - On Web: triggers a native browser download via AnchorElement.
  /// - On mobile/desktop: writes to temp dir and returns the path.
  ///
  /// Returns the path (mobile) or an empty string (web, download already fired).
  Future<String> downloadUsersCsv({
    bool? verified,
    String? role,
  }) async {
    final query = <String, dynamic>{};
    if (verified != null) query['verified'] = verified;
    if (role != null) query['role'] = role;

    final uri = Uri(
      path: '/admin/analytics/export/users.csv',
      queryParameters: query.isEmpty ? null : query,
    );

    // responseType.bytes → on force la récupération en bytes
    final response = await _dio.get<dynamic>(
      uri.toString(),
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    );

    // Dio peut renvoyer List<int>, Uint8List, ou List<dynamic> selon la plateforme
    final raw = response.data;
    List<int> bytes;
    if (raw is List<int>) {
      bytes = raw;
    } else if (raw is Uint8List) {
      bytes = raw;
    } else if (raw is List) {
      bytes = raw.map((e) => (e as num).toInt()).toList();
    } else if (raw is String) {
      bytes = raw.codeUnits;
    } else {
      throw Exception(
          'Réponse CSV inattendue (type: ${raw.runtimeType}). Attendu: bytes.');
    }

    if (bytes.length < 20) {
      throw Exception('CSV export vide ou corrompu (${bytes.length} octets)');
    }

    final fileName =
        'mindora-users-${DateTime.now().millisecondsSinceEpoch}.csv';

    if (kIsWeb) {
      _triggerWebDownload(bytes, fileName);
      return '';
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  /// Web-only helper. Uses `package:web` AnchorElement.
  void _triggerWebDownload(List<int> bytes, String fileName) {
    final uint8 = Uint8List.fromList(bytes);
    // Convert Uint8List → JSArrayBuffer → JSArray<BlobPart>
    final blobPart = uint8.buffer.toJS;
    final parts = <JSAny>[blobPart].toJS;
    final blob = web.Blob(parts, web.BlobPropertyBag(type: 'text/csv'));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }
}

// ============================================================
// RIVERPOD PROVIDERS
// ============================================================

final adminAnalyticsRepositoryProvider = Provider<AdminAnalyticsRepository>(
  (ref) => AdminAnalyticsRepository(ref.watch(dioProvider)),
);

// ---------- Phase 1 (existing, unchanged) ----------

final analyticsOverviewProvider = FutureProvider<AnalyticsOverview>((ref) async {
  return ref.watch(adminAnalyticsRepositoryProvider).overview();
});

final usersTimeseriesProvider =
    FutureProvider.family<List<TimePoint>, int>((ref, days) async {
  return ref.watch(adminAnalyticsRepositoryProvider).usersTimeseries(days: days);
});

final documentsTimeseriesProvider =
    FutureProvider.family<List<TimePoint>, int>((ref, days) async {
  return ref.watch(adminAnalyticsRepositoryProvider).documentsTimeseries(days: days);
});

final subjectsBreakdownProvider = FutureProvider<List<BreakdownItem>>((ref) async {
  return ref.watch(adminAnalyticsRepositoryProvider).subjectsBreakdown();
});

final examSystemsBreakdownProvider =
    FutureProvider<List<BreakdownItem>>((ref) async {
  return ref.watch(adminAnalyticsRepositoryProvider).examSystemsBreakdown();
});

final recentActivityProvider = FutureProvider<List<RecentActivityItem>>((ref) async {
  return ref.watch(adminAnalyticsRepositoryProvider).recentActivity();
});

// ---------- Phase 6.1 (new) ----------

final analyticsRetentionProvider =
    FutureProvider.family<RetentionResponse, int>((ref, weeks) async {
  return ref.watch(adminAnalyticsRepositoryProvider).retention(weeks: weeks);
});

final analyticsFunnelProvider =
    FutureProvider.family<FunnelResponse, int>((ref, days) async {
  return ref.watch(adminAnalyticsRepositoryProvider).funnel(days: days);
});
