/// Image picking + base64 encoding helper for Vision (Phase 11C).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.base64,
    required this.mimeType,
    required this.name,
  });

  final Uint8List bytes;
  final String base64;
  final String mimeType;
  final String name;

  int get sizeBytes => bytes.length;
  bool get isTooLarge => sizeBytes > 5 * 1024 * 1024;
}

class ImagePickerHelper {
  ImagePickerHelper._();
  static final _picker = ImagePicker();

  static Future<PickedImage?> pick({
    required ImageSource source,
    int maxWidth = 1600,
    int quality = 80,
  }) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        imageQuality: quality,
        requestFullMetadata: false,
      );
      if (xfile == null) return null;

      final bytes = await xfile.readAsBytes();
      if (bytes.isEmpty) return null;

      final mime = _inferMime(xfile.name, xfile.mimeType);
      final b64 = base64Encode(bytes);

      return PickedImage(
        bytes: bytes,
        base64: b64,
        mimeType: mime,
        name: xfile.name,
      );
    } catch (_) {
      return null;
    }
  }

  static String _inferMime(String name, String? reported) {
    if (reported != null && reported.startsWith('image/')) return reported;
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
