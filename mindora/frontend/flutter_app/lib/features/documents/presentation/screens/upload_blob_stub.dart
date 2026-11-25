// Stub for non-web platforms
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';

Future<Uint8List> readBytesWeb(XFile file, int totalSize) async {
  // Never called on native; native path uses file.readAsBytes()
  return file.readAsBytes();
}
