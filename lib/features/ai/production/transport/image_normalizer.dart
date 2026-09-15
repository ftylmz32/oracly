/// HEIC/HEIF + EXIF → app-private JPEG suitable for vision upload.
///
/// Shared by Coffee/Palm capture intake: a camera/gallery photo can carry a
/// non-identity EXIF orientation tag (very common — portrait shots stored
/// with landscape pixel data plus a rotation tag) or arrive as HEIC on iOS.
/// Vision APIs read raw pixel bytes and do not apply EXIF rotation, so an
/// un-normalized photo can reach the model sideways/upside-down and get
/// correctly-but-unhelpfully judged as not showing the subject clearly.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../../coffee/models/coffee_image_pick.dart';
import 'coffee_image_limits.dart';

class ImageNormalizeException implements Exception {
  const ImageNormalizeException(
    this.message, {
    this.kind = ImageNormalizeKind.failed,
  });
  final String message;
  final ImageNormalizeKind kind;
}

enum ImageNormalizeKind { unsupported, corrupt, failed }

/// Per-feature copy so error text stays in that feature's voice.
class ImageNormalizeMessages {
  const ImageNormalizeMessages({
    required this.missing,
    required this.unreadable,
    required this.unsupported,
    required this.normalizeFailed,
    required this.tooLarge,
  });

  final String missing;
  final String unreadable;
  final String unsupported;
  final String normalizeFailed;
  final String tooLarge;
}

abstract final class ImageNormalizer {
  ImageNormalizer._();

  static const maxEdge = 1920;
  static const quality = 88;

  /// Decode/orient/compress into an app-private working JPEG under
  /// `<support dir>/<workDirName>/`.
  ///
  /// [maxBytesOverride] lets a caller (Coffee V2's tighter 8 MiB transport
  /// ceiling) enforce a smaller cap than the shared [CoffeeImageLimits]
  /// default without changing behavior for every other caller — omitting it
  /// preserves the exact legacy Coffee/Palm limit.
  static Future<CoffeeImagePick> normalize(
    CoffeeImagePick source,
    String workDirName,
    ImageNormalizeMessages messages, {
    int? maxBytesOverride,
  }) async {
    final maxBytes = maxBytesOverride ?? CoffeeImageLimits.maxBytes;
    final file = File(source.path);
    if (!file.existsSync()) {
      throw ImageNormalizeException(
        messages.missing,
        kind: ImageNormalizeKind.corrupt,
      );
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw ImageNormalizeException(
        messages.unreadable,
        kind: ImageNormalizeKind.corrupt,
      );
    }
    final claimed = (source.mimeType ?? '').trim().toLowerCase();
    final heic = CoffeeImageLimits.looksLikeHeic(bytes) ||
        claimed.contains('heic') ||
        claimed.contains('heif');
    final sniffed = CoffeeImageLimits.sniffMime(bytes);
    if (!heic &&
        sniffed == null &&
        !CoffeeImageLimits.allowedMimes.contains(claimed)) {
      throw ImageNormalizeException(
        messages.unsupported,
        kind: ImageNormalizeKind.unsupported,
      );
    }

    final outDir = await _workDir(workDirName);
    final outPath =
        '${outDir.path}${Platform.pathSeparator}${workDirName}_${DateTime.now().microsecondsSinceEpoch}.jpg';

    // Already a valid JPEG under limits with no Exif segment at all (true
    // for synthetic test fixtures) — skip the plugin entirely so tests don't
    // depend on a platform channel. Any real camera/gallery JPEG carries an
    // Exif block (often with a rotation tag), so it always routes through
    // compress below, where autoCorrectionAngle bakes orientation in.
    if (!heic &&
        sniffed == 'image/jpeg' &&
        !_hasExifSegment(bytes) &&
        bytes.length >= CoffeeImageLimits.minBytes &&
        bytes.length <= maxBytes) {
      await File(outPath).writeAsBytes(bytes, flush: true);
      return CoffeeImagePick(path: outPath, mimeType: 'image/jpeg');
    }

    Uint8List? compressed;
    try {
      compressed = await FlutterImageCompress.compressWithFile(
        source.path,
        minWidth: maxEdge,
        minHeight: maxEdge,
        quality: quality,
        format: CompressFormat.jpeg,
        keepExif: false,
        autoCorrectionAngle: true,
      );
    } catch (_) {
      compressed = null;
    }
    if (compressed == null || compressed.isEmpty) {
      throw ImageNormalizeException(
        messages.normalizeFailed,
        kind: ImageNormalizeKind.failed,
      );
    }
    if (CoffeeImageLimits.looksLikeHeic(compressed) ||
        CoffeeImageLimits.sniffMime(compressed) != 'image/jpeg') {
      throw ImageNormalizeException(
        messages.normalizeFailed,
        kind: ImageNormalizeKind.failed,
      );
    }
    if (compressed.length > maxBytes) {
      final tighter = await FlutterImageCompress.compressWithList(
        compressed,
        minWidth: 1280,
        minHeight: 1280,
        quality: 76,
        format: CompressFormat.jpeg,
      );
      if (tighter.isEmpty || tighter.length > maxBytes) {
        throw ImageNormalizeException(
          messages.tooLarge,
          kind: ImageNormalizeKind.failed,
        );
      }
      await File(outPath).writeAsBytes(tighter, flush: true);
    } else {
      await File(outPath).writeAsBytes(compressed, flush: true);
    }
    return CoffeeImagePick(path: outPath, mimeType: 'image/jpeg');
  }

  /// Presence of a JPEG APP1 "Exif" segment — real camera/gallery photos
  /// carry one (often with a rotation tag); synthetic test fixtures usually
  /// don't. We don't need the exact orientation value, only whether Exif
  /// metadata exists at all, to decide whether baking via the compressor is
  /// worth it.
  static bool _hasExifSegment(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return false;
    var offset = 2;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset] != 0xFF) break;
      final marker = bytes[offset + 1];
      if (marker == 0xD8 || marker == 0xD9 || marker == 0xDA) break;
      if (marker < 0xD0 || marker > 0xD9) {
        final segLen = (bytes[offset + 2] << 8) | bytes[offset + 3];
        if (marker == 0xE1 &&
            offset + 4 + 4 <= bytes.length &&
            String.fromCharCodes(bytes, offset + 4, offset + 8) == 'Exif') {
          return true;
        }
        offset += 2 + segLen;
      } else {
        offset += 2;
      }
    }
    return false;
  }

  static Future<Directory> _workDir(String workDirName) async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}$workDirName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
