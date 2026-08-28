/// Soft gold/purple edge overlay from a local palm photo — cosmetic only.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Builds a translucent edge-sketch PNG for stylization.
/// Never claims detections; fail soft with null.
abstract final class PalmEdgeSketch {
  PalmEdgeSketch._();

  static const int maxEdge = 480;
  static final Map<String, Uint8List?> _cache = {};

  static void clearCache() => _cache.clear();

  /// Cached by absolute [path]. Returns null on any failure.
  static Future<Uint8List?> fromPath(String path) async {
    if (_cache.containsKey(path)) return _cache[path];
    try {
      final file = File(path);
      if (!await file.exists()) {
        _cache[path] = null;
        return null;
      }
      final bytes = await file.readAsBytes();
      final out = fromBytes(bytes);
      _cache[path] = out;
      return out;
    } catch (_) {
      _cache[path] = null;
      return null;
    }
  }

  /// Pure transform for tests and callers with bytes already loaded.
  static Uint8List? fromBytes(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null || decoded.width < 4 || decoded.height < 4) {
        return null;
      }
      final scaled = _downscale(decoded);
      var work = img.grayscale(scaled);
      work = img.contrast(work, contrast: 138);
      work = img.sobel(work, amount: 1);
      final tinted = _tintOverlay(work);
      return Uint8List.fromList(img.encodePng(tinted));
    } catch (_) {
      return null;
    }
  }

  static img.Image _downscale(img.Image src) {
    final long = src.width > src.height ? src.width : src.height;
    if (long <= maxEdge) return src;
    final scale = maxEdge / long;
    return img.copyResize(
      src,
      width: (src.width * scale).round().clamp(4, maxEdge),
      height: (src.height * scale).round().clamp(4, maxEdge),
      interpolation: img.Interpolation.average,
    );
  }

  /// Champagne gold + soft violet lines on transparent ground.
  static img.Image _tintOverlay(img.Image edges) {
    final out = img.Image(
      width: edges.width,
      height: edges.height,
      numChannels: 4,
    );
    for (final p in edges) {
      final mag = p.luminanceNormalized;
      if (mag < 0.12) {
        out.setPixelRgba(p.x, p.y, 0, 0, 0, 0);
        continue;
      }
      final t = ((mag - 0.12) / 0.88).clamp(0.0, 1.0);
      // Soft champagne -> muted violet by strength.
      final r = (212 + (148 - 212) * t * 0.35).round();
      final g = (176 + (118 - 176) * t * 0.35).round();
      final b = (118 + (168 - 118) * t * 0.55).round();
      final a = (38 + 140 * t).round().clamp(0, 178);
      out.setPixelRgba(p.x, p.y, r, g, b, a);
    }
    return out;
  }
}
