/// Decode + draw photoreal share imagery with protected crop / contain.
library;

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/oracly_chrome.dart';
import 'discovery_share_card_layout.dart';

abstract final class DiscoveryShareCardImage {
  DiscoveryShareCardImage._();

  static Future<ui.Image?> fromBytes(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image?> fromAsset(String? assetPath) async {
    if (assetPath == null || assetPath.isEmpty) return null;
    try {
      final data = await rootBundle.load(assetPath);
      return fromBytes(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static void drawProtected(
    Canvas canvas,
    ui.Image image,
    Rect dest, {
    required bool contain,
    double focusY = 0.38,
    double radius = 22,
  }) {
    final srcFull = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    late Rect src;
    late Rect paintDest;
    if (contain) {
      final fitted = DiscoveryShareCardLayout.protectedContain(srcFull, dest);
      src = fitted.$1;
      paintDest = fitted.$2;
    } else {
      src = DiscoveryShareCardLayout.protectedCover(
        srcFull,
        dest,
        focusY: focusY,
      );
      paintDest = dest;
    }

    final glow = paintDest.inflate(18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glow, Radius.circular(radius + 8)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OraclyChrome.gold.withValues(alpha: 0.18),
            OraclyChrome.violet.withValues(alpha: 0.06),
            const Color(0x00FFFFFF),
          ],
        ).createShader(glow),
    );

    final rrect = RRect.fromRectAndRadius(
      paintDest,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawImageRect(image, src, paintDest, Paint());
    canvas.drawRect(
      paintDest,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x33080512),
            Color(0x00000000),
            Color(0x77080512),
          ],
        ).createShader(paintDest),
    );
    canvas.restore();
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = OraclyChrome.gold.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }
}
