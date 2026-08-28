/// Basic palm-photo quality checks — heuristics, not hand vision.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import '../copy/palm_copy.dart';
import 'palm_image_metrics.dart';

class PalmImageValidation {
  const PalmImageValidation._({
    required this.ok,
    this.message,
    this.guidance,
  });

  const PalmImageValidation.pass({String? guidance})
      : this._(ok: true, guidance: guidance);

  const PalmImageValidation.fail(String message)
      : this._(ok: false, message: message);

  final bool ok;
  final String? message;
  final String? guidance;
}

abstract final class PalmImageValidator {
  PalmImageValidator._();

  static const minBytes = 8 * 1024;
  static const maxBytes = 12 * 1024 * 1024;
  static const minSide = 180;
  static const _probeSide = 512;

  static const hardDarkLuma = 14.0;
  static const softDarkLuma = 48.0;
  static const hardFlatStd = 3.5;
  static const softBlurEdge = 4.5;
  static const softEmptyOcc = 0.04;
  static const softTinyOcc = 0.16;

  static String? _cacheKey;
  static PalmImageValidation? _cacheHit;
  static int debugDecodeCount = 0;

  static Future<PalmImageValidation> validate(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return PalmImageValidation.fail(PalmCopy.imageMissing);
    }
    final size = await file.length();
    final key = '$path@$size';
    final hit = _cacheHit;
    if (_cacheKey == key && hit != null) return hit;
    final result = await _inspect(file, size);
    _cacheKey = key;
    _cacheHit = result;
    return result;
  }

  static Future<PalmImageValidation> _inspect(File file, int size) async {
    if (size < minBytes) {
      return PalmImageValidation.fail(PalmCopy.imageTooSmall);
    }
    if (size > maxBytes) {
      return PalmImageValidation.fail(PalmCopy.imageTooLarge);
    }
    try {
      debugDecodeCount++;
      final bytes = await file.readAsBytes();
      final codec = await instantiateImageCodec(
        bytes,
        targetWidth: _probeSide,
        targetHeight: _probeSide,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      final metrics = await PalmImageMetrics.fromImage(image);
      image.dispose();
      codec.dispose();
      if (width < minSide || height < minSide) {
        return PalmImageValidation.fail(PalmCopy.imageTooSmall);
      }
      if (metrics == null) return const PalmImageValidation.pass();
      return _fromMetrics(metrics);
    } catch (_) {
      return PalmImageValidation.fail(PalmCopy.imageUnreadable);
    }
  }

  @visibleForTesting
  static PalmImageValidation assessMetrics(PalmImageMetrics m) =>
      _fromMetrics(m);

  static PalmImageValidation _fromMetrics(PalmImageMetrics m) {
    // Soft guidance only — keep the photo, help the user improve it.
    return PalmImageValidation.pass(guidance: _softTip(m));
  }

  static String? _softTip(PalmImageMetrics m) {
    if (m.meanLuma < softDarkLuma || m.meanLuma < hardDarkLuma) {
      return PalmCopy.qualityBrighten;
    }
    if (m.lumaStdDev < hardFlatStd || m.occupancy < softEmptyOcc) {
      return PalmCopy.qualityMissing;
    }
    if (m.occupancy < softTinyOcc && m.blobCount <= 1) {
      return PalmCopy.qualityCloser;
    }
    if (m.blobCount >= 2) return PalmCopy.qualityOneHand;
    if (_looksCropped(m)) return PalmCopy.qualityFrame;
    if (m.edgeEnergy < softBlurEdge) return PalmCopy.qualityBlur;
    return null;
  }

  static bool _looksCropped(PalmImageMetrics m) {
    if (m.borderOccupancy > 0.2 &&
        m.centerOccupancy < m.borderOccupancy * 0.45) {
      return true;
    }
    final ratio = m.width / math.max(m.height, 1);
    return ratio > 2.4 || ratio < 0.42;
  }
}
