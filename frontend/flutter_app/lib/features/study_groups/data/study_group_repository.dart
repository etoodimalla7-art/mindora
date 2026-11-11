import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/env.dart';
import '../../../core/network/token_store.dart';
import '../domain/study_group_models.dart';

/// Events emitted by the group WebSocket.
sealed class GroupSocketEvent {}

class GroupSocketMessage extends GroupSocketEvent {
  GroupSocketMessage(this.message);
  final GroupMessage message;
}

class GroupSocketPresence extends GroupSocketEvent {
  GroupSocketPresence(this.count);
  final int count;
}

class GroupSocketError extends GroupSocketEvent {
  GroupSocketError(this.message);
  final String message;
}

class StudyGroupRepository {
  StudyGroupRepository(this._dio);
  final Dio _dio;
  final _tokenStore = TokenStore();

  // ---------- REST ----------

  Future<List<StudyGroup>> listGroups({
    String? subject,
    String? examSystem,
    String? examLevel,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (subject != null) params['subject'] = subject;
    if (examSystem != null) params['exam_system'] = examSystem;
    if (examLevel != null) params['exam_level'] = examLevel;
    if (search != null) params['search'] = search;

    final r = await _dio.get('/study-groups', queryParameters: params);
    return (r.data as List)
        .map((e) => StudyGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudyGroup> createGroup({
    required String name,
    String? description,
    String? subject,
    String? examSystem,
    String? examLevel,
    bool isPrivate = false,
  }) async {
    final r = await _dio.post('/study-groups', data: {
      'name': name,
      if (description != null) 'description': description,
      if (subject != null) 'subject': subject,
      if (examSystem != null) 'exam_system': examSystem,
      if (examLevel != null) 'exam_level': examLevel,
      'is_private': isPrivate,
    });
    return StudyGroup.fromJson(r.data as Map<String, dynamic>);
  }

  Future<StudyGroup> getGroup(String id) async {
    final r = await _dio.get('/study-groups/$id');
    return StudyGroup.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> joinGroup(String id) async {
    await _dio.post('/study-groups/$id/join');
  }

  Future<void> leaveGroup(String id) async {
    await _dio.post('/study-groups/$id/leave');
  }

  Future<List<GroupMessage>> listMessages(String groupId,
      {int limit = 50}) async {
    final r = await _dio.get('/study-groups/$groupId/messages',
        queryParameters: {'limit': limit});
    return (r.data as List)
        .map((e) => GroupMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GroupMessage> postMessage(String groupId, String content) async {
    final r = await _dio.post(
      '/study-groups/$groupId/messages',
      data: {'content': content},
    );
    return GroupMessage.fromJson(r.data as Map<String, dynamic>);
  }

  // ---------- WebSocket ----------

  Stream<GroupSocketEvent> connectSocket(String groupId) async* {
    final token = await _tokenStore.access;
    if (token == null || token.isEmpty) {
      yield GroupSocketError('Not authenticated.');
      return;
    }

    final base = Env.apiBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final url = '$base/study-groups/$groupId/ws?token=$token';

    final channel = WebSocketChannel.connect(Uri.parse(url));
    try {
      await channel.ready;
    } catch (e) {
      yield GroupSocketError('WS connection failed: $e');
      return;
    }

    final controller = StreamController<GroupSocketEvent>();
    final sub = channel.stream.listen(
      (raw) {
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          final type = data['type'] as String?;
          if (type == 'message') {
            controller.add(GroupSocketMessage(GroupMessage.fromJson(
                data['data'] as Map<String, dynamic>)));
          } else if (type == 'presence') {
            controller.add(GroupSocketPresence(data['count'] as int? ?? 0));
          } else if (type == 'error') {
            controller.add(
                GroupSocketError(data['message'] as String? ?? 'Error'));
          }
        } catch (_) {
          // ignore malformed
        }
      },
      onError: (e) => controller.add(GroupSocketError('WS error: $e')),
      onDone: () => controller.close(),
      cancelOnError: false,
    );

    try {
      yield* controller.stream;
    } finally {
      await sub.cancel();
      await channel.sink.close();
    }
  }
}
