/// Web implementation for triggering browser file downloads via package:web.
library;

import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void triggerWebDownload(List<int> bytes, String fileName, String mimeType) {
  final uint8 = Uint8List.fromList(bytes);
  final blobPart = uint8.buffer.toJS;
  final parts = <JSAny>[blobPart].toJS;
  final blob = web.Blob(parts, web.BlobPropertyBag(type: mimeType));
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
