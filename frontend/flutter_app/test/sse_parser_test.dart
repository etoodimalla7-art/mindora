import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindora_app/features/ai/data/sse_parser.dart';

void main() {
  group('SseParser', () {
    test('parses single event', () {
      final p = SseParser();
      final events = p.feed(utf8.encode('event: token\ndata: {"text":"hi"}\n\n'));
      expect(events.length, 1);
      expect(events[0].event, 'token');
      expect(events[0].data, '{"text":"hi"}');
    });

    test('parses multiple events in one chunk', () {
      final p = SseParser();
      final events = p.feed(utf8.encode(
        'event: meta\ndata: {"conversation_id":"abc"}\n\n'
        'event: token\ndata: {"text":"A"}\n\n'
        'event: token\ndata: {"text":"B"}\n\n',
      ));
      expect(events.length, 3);
    });

    test('handles \\r\\n\\r\\n separators', () {
      final p = SseParser();
      final events = p.feed(utf8.encode('event: token\r\ndata: {"text":"hi"}\r\n\r\n'));
      expect(events.length, 1);
    });

    test('handles split chunks', () {
      final p = SseParser();
      final e1 = p.feed(utf8.encode('event: token\nda'));
      final e2 = p.feed(utf8.encode('ta: {"text":"hi"}\n\n'));
      expect(e1.length, 0);
      expect(e2.length, 1);
    });

    test('ignores ping lines', () {
      final p = SseParser();
      final events = p.feed(utf8.encode(': ping\n\nevent: token\ndata: {"text":"x"}\n\n'));
      expect(events.length, 1);
      expect(events[0].data, '{"text":"x"}');
    });
  });
}
