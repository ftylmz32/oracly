/// Proxy-decoded soul-mate portrait — never a fabricated URL.
library;

import 'dart:convert';
import 'dart:typed_data';

class SoulMateAiPortrait {
  const SoulMateAiPortrait({
    required this.bytes,
    this.mimeType = 'image/png',
  });

  final List<int> bytes;
  final String mimeType;

  bool get hasImage => bytes.isNotEmpty;

  /// Decode proxy base64 only when bytes look like PNG / JPEG / WebP.
  static SoulMateAiPortrait? tryFromBase64(
    String raw, {
    String? mimeType,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    late final Uint8List bytes;
    try {
      bytes = base64Decode(trimmed);
    } on FormatException {
      return null;
    }
    if (!_looksLikeImage(bytes)) return null;
    final mime = (mimeType ?? '').trim();
    return SoulMateAiPortrait(
      bytes: bytes,
      mimeType: mime.isNotEmpty ? mime : _guessMime(bytes),
    );
  }

  static bool _looksLikeImage(List<int> bytes) {
    if (bytes.length < 12) return false;
    // PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }
    // WebP: RIFF....WEBP
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    return false;
  }

  static String _guessMime(List<int> bytes) {
    if (bytes[0] == 0xFF) return 'image/jpeg';
    if (bytes[0] == 0x52) return 'image/webp';
    return 'image/png';
  }
}
