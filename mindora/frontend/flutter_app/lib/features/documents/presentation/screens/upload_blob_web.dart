// Web-only implementation for reading file chunks
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';

Future<Uint8List> readBytesWeb(XFile file, int totalSize) async {
  final builder = BytesBuilder(copy: false);
  // XFile on web doesn't expose the JS Blob directly, but openRead
  // internally uses Blob.slice on the web implementation of file_selector.
  // This is a placeholder; for true Blob.slice you'd need the raw HTML File.
  final stream = file.openRead();
  await for (final chunk in stream) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}
