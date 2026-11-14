/// Real-time admin events client (WebSocket).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/env.dart';
import '../../../core/network/token_store.dart';

class AdminEvent {
  const AdminEvent({required this.type, required this.payload, required this.timestamp});
  final String type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  factory AdminEvent.fromJson(Map<String, dynamic> j) => AdminEvent(
        type: j['type'] as String,
        payload: (j['payload'] as Map<String, dynamic>?) ?? {},
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

sealed class AdminEventStreamState {}

class AdminEventConnected extends AdminEventStreamState {
  AdminEventConnected(this.permissionsCount);
  final int permissionsCount;
}

class AdminEventReceived extends AdminEventStreamState {
  AdminEventReceived(this.event);
  final AdminEvent event;
}

class AdminEventDisconnected extends AdminEventStreamState {
  AdminEventDisconnected(this.reason);
  final String reason;
}

class AdminEventsRepository {
  AdminEventsRepository(this._tokenStore);
  final TokenStore _tokenStore;

  Stream<AdminEventStreamState> connect() async* {
    final token = await _tokenStore.access;
    if (token == null || token.isEmpty) {
      yield AdminEventDisconnected('Not authenticated.');
      return;
    }

    final base = Env.apiBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final url = '$base/admin/events?token=$token';

    WebSocketChannel channel;
    try {
      channel = WebSocketChannel.connect(Uri.parse(url));
      await channel.ready;
    } catch (e) {
      yield AdminEventDisconnected('WS failed: $e');
      return;
    }

    final controller = StreamController<AdminEventStreamState>();
    final sub = channel.stream.listen(
      (raw) {
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          final type = data['type'] as String?;
          if (type == 'connected') {
            final p = data['payload'] as Map<String, dynamic>? ?? {};
            controller.add(AdminEventConnected((p['permissions_count'] as int?) ?? 0));
          } else if (type == 'pong') {
            // ignore
          } else if (type != null) {
            controller.add(AdminEventReceived(AdminEvent.fromJson(data)));
          }
        } catch (_) {}
      },
      onError: (e) => controller.add(AdminEventDisconnected('WS error: $e')),
      onDone: () => controller.add(AdminEventDisconnected('WS closed')),
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

final adminEventsRepositoryProvider = Provider<AdminEventsRepository>(
  (ref) => AdminEventsRepository(TokenStore()),
);

/// Stream provider of admin events.
final adminEventsStreamProvider = StreamProvider<AdminEventStreamState>((ref) {
  return ref.watch(adminEventsRepositoryProvider).connect();
});
