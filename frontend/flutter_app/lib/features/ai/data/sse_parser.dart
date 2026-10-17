/// Robust SSE parser that handles:
/// - \n\n AND \r\n\r\n separators
/// - Multi-byte UTF-8 characters split across chunks
/// - Ping lines (starting with :)
/// - Events with `event:` + `data:` fields
library;

import 'dart:convert';

class SseEvent {
  final String? event;
  final String data;

  SseEvent({this.event, required this.data});

  @override
  String toString() => 'SseEvent(event=$event, data=${data.length} chars)';
}

class SseParser {
  /// Internal UTF-8 decoder that preserves incomplete multi-byte sequences.
  final _decoder = const Utf8Decoder(allowMalformed: true);
  final StringBuffer _raw = StringBuffer();

  /// Feed raw bytes, return list of complete events parsed.
  List<SseEvent> feed(List<int> bytes) {
    _raw.write(_decoder.convert(bytes));
    return _drain();
  }

  /// Flush remaining content (e.g. when connection closes).
  List<SseEvent> close() {
    // Try one last drain in case buffer holds a complete event without trailing \n\n
    return _drain(flush: true);
  }

  List<SseEvent> _drain({bool flush = false}) {
    final out = <SseEvent>[];
    while (true) {
      final buf = _raw.toString();
      // Find earliest separator (\r\n\r\n or \n\n)
      final idxA = buf.indexOf('\n\n');
      final idxB = buf.indexOf('\r\n\r\n');

      int sepStart = -1;
      int sepLen = 0;
      if (idxA != -1 && (idxB == -1 || idxA < idxB)) {
        sepStart = idxA;
        sepLen = 2;
      } else if (idxB != -1) {
        sepStart = idxB;
        sepLen = 4;
      }

      if (sepStart == -1) {
        if (flush && buf.isNotEmpty) {
          // Flush partial as one event (best-effort)
          final ev = _parseBlock(buf);
          _raw.clear();
          if (ev != null) out.add(ev);
        }
        break;
      }

      final block = buf.substring(0, sepStart);
      final rest = buf.substring(sepStart + sepLen);
      _raw.clear();
      _raw.write(rest);

      final ev = _parseBlock(block);
      if (ev != null) out.add(ev);
    }
    return out;
  }

  SseEvent? _parseBlock(String block) {
    String? event;
    final data = StringBuffer();
    for (final line in block.split(RegExp(r'\r?\n'))) {
      if (line.isEmpty) continue;
      if (line.startsWith(':')) continue; // comment / ping
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        if (data.isNotEmpty) data.write('\n');
        data.write(line.substring(5).trimLeft());
      }
    }
    if (data.isEmpty) return null;
    return SseEvent(event: event, data: data.toString());
  }
}
