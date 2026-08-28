/// HEIC/HEIF + EXIF to app-private JPEG suitable for vision upload.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../ai/production/transport/coffee_image_limits.dart';
import '../../coffee/models/coffee_image_pick.dart';
import '../copy/palm_copy.dart';

class PalmNormalizeException implements Exception {
  const PalmNormalizeException(
    this.message, {
    this.kind = PalmNormalizeKind.failed,
  });
  final String message;
  final PalmNormalizeKind kind;
}

enum PalmNormalizeKind { unsupported, corrupt, failed }

abstract final class PalmImageNormalizer {
  PalmImageNormalizer._();

  static const maxEdge = 1920;
  static const quality = 88;

  /// Decode/orient/compress into app-private working JPEG.
  static Future<CoffeeImagePick> normalize(CoffeeImagePick source) async {
    final file = File(source.path);
    if (!await file.exists()) {
      throw PalmNormalizeException(
        PalmCopy.imageMissing,
        kind: PalmNormalizeKind.corrupt,
      );
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw PalmNormalizeException(
        PalmCopy.imageUnreadable,
        kind: PalmNormalizeKind.corrupt,
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
      throw PalmNormalizeException(
        PalmCopy.imageUnsupported,
        kind: PalmNormalizeKind.unsupported,
      );
    }

    final outDir = await _workDir();
    final outPath =
        '${outDir.path}${Platform.pathSeparator}palm_work_${DateTime.now().microsecondsSinceEpoch}.jpg';

    // Already a valid JPEG under limits — avoid plugin hangs on desktop tests.
    if (!heic &&
        sniffed == 'image/jpeg' &&
        bytes.length >= CoffeeImageLimits.minBytes &&
        bytes.length <= CoffeeImageLimits.maxBytes) {
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
      throw PalmNormalizeException(
        PalmCopy.imageNormalizeFailed,
        kind: PalmNormalizeKind.failed,
      );
    }
    if (CoffeeImageLimits.looksLikeHeic(compressed) ||
        CoffeeImageLimits.sniffMime(compressed) != 'image/jpeg') {
      throw PalmNormalizeException(
        PalmCopy.imageNormalizeFailed,
        kind: PalmNormalizeKind.failed,
      );
    }
    if (compressed.length > CoffeeImageLimits.maxBytes) {
      final tighter = await FlutterImageCompress.compressWithList(
        compressed,
        minWidth: 1280,
        minHeight: 1280,
        quality: 76,
        format: CompressFormat.jpeg,
      );
      if (tighter.isEmpty || tighter.length > CoffeeImageLimits.maxBytes) {
        throw PalmNormalizeException(
          PalmCopy.imageTooLarge,
          kind: PalmNormalizeKind.failed,
        );
      }
      await File(outPath).writeAsBytes(tighter, flush: true);
    } else {
      await File(outPath).writeAsBytes(compressed, flush: true);
    }
    return CoffeeImagePick(path: outPath, mimeType: 'image/jpeg');
  }

  static Future<Directory> _workDir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}palm_work');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
