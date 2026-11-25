import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/env.dart';
import '../../../core/network/token_store.dart';
import '../domain/dm_models.dart';

sealed class DmSocketEvent {}

class DmSocketMessage extends DmSocketEvent {
  DmSocketMessage(this.message);
  final DirectMessage message;
}

class DmSocketError extends DmSocketEvent {
  DmSocketError(this.message);
  final String message;
}

class DmRepository {
  DmRepository(this._dio);
  final Dio _dio;
  final _tokenStore = TokenStore();

  Future<List<DirectConversation>> listConversations() async {
    final r = await _dio.get('/direct-conversations');
    return (r.data as List)
        .map((e) => DirectConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DirectConversation> getOrCreate(String peerUserId) async {
    final r = await _dio.post(
      '/direct-conversations',
      data: {'peer_user_id': peerUserId},
    );
    return DirectConversation.fromJson(r.data as Map<String, dynamic>);
  }

  Future<DirectConversation> getConversation(String id) async {
    final r = await _dio.get('/direct-conversations/$id');
    return DirectConversation.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<DirectMessage>> listMessages(String conversationId,
      {int limit = 50}) async {
    final r = await _dio.get(
      '/direct-conversations/$conversationId/messages',
      queryParameters: {'limit': limit},
    );
    return (r.data as List)
        .map((e) => DirectMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DirectMessage> postMessage(
      String conversationId, String content) async {
    final r = await _dio.post(
      '/direct-conversations/$conversationId/messages',
      data: {'content': content},
    );
    return DirectMessage.fromJson(r.data as Map<String, dynamic>);
  }

  Stream<DmSocketEvent> connectSocket(String conversationId) async* {
    final token = await _tokenStore.access;
    if (token == null || token.isEmpty) {
      yield DmSocketError('Not authenticated.');
      return;
    }
    final base = Env.apiBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final url = '$base/direct-conversations/$conversationId/ws?token=$token';

    final channel = WebSocketChannel.connect(Uri.parse(url));
    try {
      await channel.ready;
    } catch (e) {
      yield DmSocketError('WS connection failed: $e');
      return;
    }

    final controller = StreamController<DmSocketEvent>();
    final sub = channel.stream.listen(
      (raw) {
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          if (data['type'] == 'message') {
            controller.add(DmSocketMessage(
              DirectMessage.fromJson(data['data'] as Map<String, dynamic>),
            ));
          } else if (data['type'] == 'error') {
            controller.add(
                DmSocketError(data['message'] as String? ?? 'Error'));
          }
        } catch (_) {}
      },
      onError: (e) => controller.add(DmSocketError('WS error: $e')),
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
