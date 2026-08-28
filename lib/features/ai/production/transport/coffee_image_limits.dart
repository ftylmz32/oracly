/// Coffee vision payload limits — client defense, not the security boundary.
library;

import '../ai_failure.dart';
import '../../../coffee/copy/coffee_copy.dart';

abstract final class CoffeeImageLimits {
  CoffeeImageLimits._();

  static const minBytes = 8 * 1024;
  static const maxBytes = 12 * 1024 * 1024;
  static const allowedMimes = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  };

  /// Prefer magic bytes over gallery-claimed mime (HEIC often mislabeled).
  static String? sniffMime(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        _ascii(bytes, 0, 4) == 'RIFF' &&
        _ascii(bytes, 8, 12) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }

  static bool looksLikeHeic(List<int> bytes) {
    if (bytes.length < 12) return false;
    if (_ascii(bytes, 4, 8) != 'ftyp') return false;
    final brand = _ascii(bytes, 8, 12).toLowerCase();
    return brand.contains('heic') ||
        brand.contains('heif') ||
        brand == 'mif1' ||
        brand == 'msf1';
  }

  static String resolveMime({
    required List<int> bytes,
    required String claimedMime,
  }) {
    final sniffed = sniffMime(bytes);
    if (sniffed != null) return sniffed;
    final claimed = claimedMime.trim().toLowerCase();
    if (claimed == 'image/jpg') return 'image/jpeg';
    if (allowedMimes.contains(claimed)) return claimed;
    return claimed;
  }

  static AiFailure? validate({
    required List<int> bytes,
    required String mimeType,
  }) {
    if (looksLikeHeic(bytes)) {
      return AiFailure.invalidImage(CoffeeCopy.imageUnclear);
    }
    final mime = resolveMime(bytes: bytes, claimedMime: mimeType);
    if (!allowedMimes.contains(mime) || sniffMime(bytes) == null) {
      return AiFailure.invalidImage(CoffeeCopy.imageUnclear);
    }
    if (bytes.length < minBytes || bytes.length > maxBytes) {
      return AiFailure.invalidImage(CoffeeCopy.imageUnclear);
    }
    return null;
  }

  static String _ascii(List<int> bytes, int start, int end) =>
      String.fromCharCodes(bytes.sublist(start, end));
}
