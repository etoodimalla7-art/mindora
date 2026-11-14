/// Admin Support Center API client (Phase 6.2).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

// ---------- DTOs ----------

class SupportTicketRow {
  const SupportTicketRow({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.assignedTo,
    required this.userId,
    this.userEmail,
    this.assignedToEmail,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String? assignedTo;
  final String userId;
  final String? userEmail;
  final String? assignedToEmail;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SupportTicketRow.fromJson(Map<String, dynamic> j) => SupportTicketRow(
        id: j['id'] as String,
        subject: j['subject'] as String? ?? '',
        description: j['description'] as String? ?? '',
        status: j['status'] as String? ?? 'open',
        priority: j['priority'] as String? ?? 'normal',
        assignedTo: j['assigned_to'] as String?,
        userId: j['user_id'] as String,
        userEmail: j['user_email'] as String?,
        assignedToEmail: j['assigned_to_email'] as String?,
        resolvedAt: j['resolved_at'] != null
            ? DateTime.parse(j['resolved_at'] as String)
            : null,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

class SupportMessageOut {
  const SupportMessageOut({
    required this.id,
    required this.ticketId,
    required this.authorId,
    this.authorEmail,
    required this.body,
    required this.isAdmin,
    required this.createdAt,
  });

  final String id;
  final String ticketId;
  final String authorId;
  final String? authorEmail;
  final String body;
  final bool isAdmin;
  final DateTime createdAt;

  factory SupportMessageOut.fromJson(Map<String, dynamic> j) => SupportMessageOut(
        id: j['id'] as String,
        ticketId: j['ticket_id'] as String,
        authorId: j['author_id'] as String,
        authorEmail: j['author_email'] as String?,
        body: j['body'] as String? ?? '',
        isAdmin: j['is_admin'] as bool? ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class SupportTicketDetail extends SupportTicketRow {
  const SupportTicketDetail({
    required super.id,
    required super.subject,
    required super.description,
    required super.status,
    required super.priority,
    super.assignedTo,
    required super.userId,
    super.userEmail,
    super.assignedToEmail,
    super.resolvedAt,
    required super.createdAt,
    required super.updatedAt,
    required this.messages,
  });

  final List<SupportMessageOut> messages;

  factory SupportTicketDetail.fromJson(Map<String, dynamic> j) => SupportTicketDetail(
        id: j['id'] as String,
        subject: j['subject'] as String? ?? '',
        description: j['description'] as String? ?? '',
        status: j['status'] as String? ?? 'open',
        priority: j['priority'] as String? ?? 'normal',
        assignedTo: j['assigned_to'] as String?,
        userId: j['user_id'] as String,
        userEmail: j['user_email'] as String?,
        assignedToEmail: j['assigned_to_email'] as String?,
        resolvedAt: j['resolved_at'] != null
            ? DateTime.parse(j['resolved_at'] as String)
            : null,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        messages: (j['messages'] as List<dynamic>? ?? [])
            .map((e) => SupportMessageOut.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SupportTicketListResponse {
  const SupportTicketListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<SupportTicketRow> items;
  final int total;
  final int limit;
  final int offset;

  factory SupportTicketListResponse.fromJson(Map<String, dynamic> j) =>
      SupportTicketListResponse(
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => SupportTicketRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: j['total'] as int? ?? 0,
        limit: j['limit'] as int? ?? 50,
        offset: j['offset'] as int? ?? 0,
      );
}

class SupportStats {
  const SupportStats({
    required this.total,
    required this.open,
    required this.inProgress,
    required this.resolved,
    required this.closed,
    required this.byPriority,
  });

  final int total;
  final int open;
  final int inProgress;
  final int resolved;
  final int closed;
  final Map<String, int> byPriority;

  factory SupportStats.fromJson(Map<String, dynamic> j) => SupportStats(
        total: j['total'] as int? ?? 0,
        open: j['open'] as int? ?? 0,
        inProgress: j['in_progress'] as int? ?? 0,
        resolved: j['resolved'] as int? ?? 0,
        closed: j['closed'] as int? ?? 0,
        byPriority: (j['by_priority'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int)),
      );
}

// ---------- Repository ----------

class AdminSupportRepository {
  AdminSupportRepository(this._dio);
  final Dio _dio;

  Future<SupportTicketListResponse> listTickets({
    String? status,
    String? priority,
    String? assignedTo,
    String? q,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{'limit': limit, 'offset': offset};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (priority != null && priority.isNotEmpty) query['priority'] = priority;
    if (assignedTo != null && assignedTo.isNotEmpty) query['assigned_to'] = assignedTo;
    if (q != null && q.isNotEmpty) query['q'] = q;

    final r = await _dio.get<Map<String, dynamic>>(
      '/admin/support/tickets',
      queryParameters: query,
    );
    return SupportTicketListResponse.fromJson(r.data!);
  }

  Future<SupportTicketDetail> getTicket(String id) async {
    final r = await _dio.get<Map<String, dynamic>>('/admin/support/tickets/$id');
    return SupportTicketDetail.fromJson(r.data!);
  }

  Future<SupportTicketRow> createTicket({
    required String subject,
    required String description,
    String priority = 'normal',
    String? userId,
  }) async {
    final body = <String, dynamic>{
      'subject': subject,
      'description': description,
      'priority': priority,
    };
    if (userId != null) body['user_id'] = userId;

    final r = await _dio.post<Map<String, dynamic>>(
      '/admin/support/tickets',
      data: body,
    );
    return SupportTicketRow.fromJson(r.data!);
  }

  Future<SupportMessageOut> respond(String ticketId, String body) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/admin/support/tickets/$ticketId/messages',
      data: {'body': body},
    );
    return SupportMessageOut.fromJson(r.data!);
  }

  Future<SupportTicketRow> assign(String ticketId, String adminId) async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/admin/support/tickets/$ticketId/assign',
      data: {'assigned_to': adminId},
    );
    return SupportTicketRow.fromJson(r.data!);
  }

  Future<SupportTicketRow> updateStatus(String ticketId, String status) async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/admin/support/tickets/$ticketId/status',
      data: {'status': status},
    );
    return SupportTicketRow.fromJson(r.data!);
  }

  Future<SupportStats> stats() async {
    final r = await _dio.get<Map<String, dynamic>>('/admin/support/stats');
    return SupportStats.fromJson(r.data!);
  }
}

// ---------- Providers ----------

final adminSupportRepositoryProvider = Provider<AdminSupportRepository>(
  (ref) => AdminSupportRepository(ref.watch(dioProvider)),
);

/// Filters for ticket list — (status, priority, q).
typedef SupportFilters = ({String? status, String? priority, String? q});

final supportTicketsProvider =
    FutureProvider.family<SupportTicketListResponse, SupportFilters>(
        (ref, filters) async {
  return ref.watch(adminSupportRepositoryProvider).listTickets(
        status: filters.status,
        priority: filters.priority,
        q: filters.q,
      );
});

final supportTicketDetailProvider =
    FutureProvider.family<SupportTicketDetail, String>((ref, id) async {
  return ref.watch(adminSupportRepositoryProvider).getTicket(id);
});

final supportStatsProvider = FutureProvider<SupportStats>((ref) async {
  return ref.watch(adminSupportRepositoryProvider).stats();
});
