/// Admin analytics API client + Riverpod providers.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

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
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        count: (j[countKey] as int?) ?? 0,
      );
}

class BreakdownItem {
  BreakdownItem({required this.label, required this.count});
  final String label;
  final int count;

  factory BreakdownItem.fromJson(Map<String, dynamic> j, {String labelKey = 'subject'}) =>
      BreakdownItem(
        label: j[labelKey] as String? ?? 'Unknown',
        count: (j['count'] as int?) ?? 0,
      );
}

class RecentActivityItem {
  RecentActivityItem({
    required this.id,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    required this.adminEmail,
    required this.result,
    required this.createdAt,
  });

  final String id;
  final String action;
  final String? resourceType;
  final String? resourceId;
  final String? adminEmail;
  final String result;
  final DateTime createdAt;

  factory RecentActivityItem.fromJson(Map<String, dynamic> j) =>
      RecentActivityItem(
        id: j['id'] as String,
        action: j['action'] as String,
        resourceType: j['resource_type'] as String?,
        resourceId: j['resource_id'] as String?,
        adminEmail: j['admin_email'] as String?,
        result: j['result'] as String? ?? 'success',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class AdminAnalyticsRepository {
  AdminAnalyticsRepository(this._dio);
  final Dio _dio;

  Future<AnalyticsOverview> overview() async {
    final r = await _dio.get('/admin/analytics/overview');
    return AnalyticsOverview.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<TimePoint>> usersTimeseries({int days = 7}) async {
    final r = await _dio.get(
      '/admin/analytics/users-timeseries',
      queryParameters: {'days': days},
    );
    return (r.data as List)
        .map((e) => TimePoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TimePoint>> documentsTimeseries({int days = 7}) async {
    final r = await _dio.get(
      '/admin/analytics/documents-timeseries',
      queryParameters: {'days': days},
    );
    return (r.data as List)
        .map((e) => TimePoint.fromJson(e as Map<String, dynamic>, countKey: 'submitted'))
        .toList();
  }

  Future<List<BreakdownItem>> subjectsBreakdown() async {
    final r = await _dio.get('/admin/analytics/subjects-breakdown');
    return (r.data as List)
        .map((e) => BreakdownItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BreakdownItem>> examSystemsBreakdown() async {
    final r = await _dio.get('/admin/analytics/exam-systems-breakdown');
    return (r.data as List)
        .map((e) => BreakdownItem.fromJson(e as Map<String, dynamic>, labelKey: 'system'))
        .toList();
  }

  Future<List<RecentActivityItem>> recentActivity({int limit = 20}) async {
    final r = await _dio.get(
      '/admin/analytics/recent-activity',
      queryParameters: {'limit': limit},
    );
    return (r.data as List)
        .map((e) => RecentActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ---------- Riverpod providers ----------

final adminAnalyticsRepositoryProvider = Provider<AdminAnalyticsRepository>(
  (ref) => AdminAnalyticsRepository(ref.watch(dioProvider)),
);

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
