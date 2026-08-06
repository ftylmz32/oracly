/// OR-500 — Anti-aliased paint defaults for all orb painters.
library;

import 'package:flutter/material.dart';

/// Shared high-quality paint factory — consistent edge smoothness.
abstract final class OrbPaint {
  OrbPaint._();

  static Paint aa({
    Color? color,
    BlendMode? blendMode,
    PaintingStyle style = PaintingStyle.fill,
    StrokeCap strokeCap = StrokeCap.round,
    double? strokeWidth,
    Shader? shader,
    MaskFilter? maskFilter,
  }) {
    return Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..color = color ?? const Color(0x00000000)
      ..blendMode = blendMode ?? BlendMode.srcOver
      ..style = style
      ..strokeCap = strokeCap
      ..strokeWidth = strokeWidth ?? 0
      ..shader = shader
      ..maskFilter = maskFilter;
  }
}
