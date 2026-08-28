/// Basic coffee-cup image quality checks — heuristics, not cup vision.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import '../copy/coffee_copy.dart';
import 'coffee_image_metrics.dart';

class CoffeeImageValidation {
  const CoffeeImageValidation._({
    required this.ok,
    this.message,
    this.guidance,
  });

  const CoffeeImageValidation.pass({String? guidance})
      : this._(ok: true, guidance: guidance);

  const CoffeeImageValidation.fail(String message)
      : this._(ok: false, message: message);

  final bool ok;
  final String? message;
  final String? guidance;
}

abstract final class CoffeeImageValidator {
  CoffeeImageValidator._();

  static const minBytes = 8 * 1024;
  static const maxBytes = 12 * 1024 * 1024;
  static const minSide = 180;
  static const _probeSide = 512;

  /// Near-black only — ambiguous dim photos stay soft.
  static const hardDarkLuma = 14.0;
  static const softDarkLuma = 48.0;
  static const hardFlatStd = 3.5;
  static const softBlurEdge = 4.5;
  static const softFrameCenter = 10.0;

  static String? _cacheKey;
  static CoffeeImageValidation? _cacheHit;
  static int debugDecodeCount = 0;

  static Future<CoffeeImageValidation> validate(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return CoffeeImageValidation.fail(CoffeeCopy.imageMissing);
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

  static Future<CoffeeImageValidation> _inspect(File file, int size) async {
    if (size < minBytes) {
      return CoffeeImageValidation.fail(CoffeeCopy.imageTooDarkOrSmall);
    }
    if (size > maxBytes) {
      return CoffeeImageValidation.fail(CoffeeCopy.imageTooLarge);
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
      final metrics = await CoffeeImageMetrics.fromImage(image);
      image.dispose();
      codec.dispose();
      if (width < minSide || height < minSide) {
        return CoffeeImageValidation.fail(CoffeeCopy.imageUnclear);
      }
      if (metrics == null) return const CoffeeImageValidation.pass();
      return _fromMetrics(metrics);
    } catch (_) {
      return CoffeeImageValidation.fail(CoffeeCopy.imageUnreadable);
    }
  }

  @visibleForTesting
  static CoffeeImageValidation assessMetrics(CoffeeImageMetrics m) =>
      _fromMetrics(m);

  static CoffeeImageValidation _fromMetrics(CoffeeImageMetrics m) {
    // Help the user fix the frame — never blind-reject a usable photo.
    String? guidance;
    if (m.meanLuma < softDarkLuma || m.meanLuma < hardDarkLuma) {
      guidance = CoffeeCopy.qualityBrighten;
    } else if (m.lumaStdDev < hardFlatStd || _looksPoorlyFramed(m)) {
      guidance = CoffeeCopy.qualityFrame;
    } else if (m.edgeEnergy < softBlurEdge) {
      guidance = CoffeeCopy.qualityBlur;
    }
    return CoffeeImageValidation.pass(guidance: guidance);
  }

  static bool _looksPoorlyFramed(CoffeeImageMetrics m) {
    if (m.centerVariance < softFrameCenter && m.borderVariance > 40) {
      return true;
    }
    if (m.centerVariance < softFrameCenter && m.lumaStdDev > 12) {
      return true;
    }
    final ratio = m.width / math.max(m.height, 1);
    return ratio > 2.4 || ratio < 0.42;
  }
}
