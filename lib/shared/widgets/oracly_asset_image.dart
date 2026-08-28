/// OR-006 — Reusable asset image with vector fallback support.
library;

import 'package:flutter/material.dart';

import '../../core/performance/oracly_decode_cache.dart';
import '../../core/theme/oracly_quiet_motion.dart';

/// Loads [assetPath] via [Image.asset]; renders [fallback] when the asset fails.
class OraclyAssetImage extends StatelessWidget {
  const OraclyAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallback,
    this.fallbackAsset,
    this.color,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.cacheCapPx = 2048,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;
  final String? fallbackAsset;
  final Color? color;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final int cacheCapPx;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final constrained = OraclyQuietMotion.constrained(context);
    final cap = constrained
        ? (cacheCapPx < 1024 ? cacheCapPx : 1024)
        : cacheCapPx;
    final quality = constrained && filterQuality == FilterQuality.high
        ? FilterQuality.medium
        : filterQuality;
    if (width != null || height != null) {
      return _paint(
        oraclyDecodeCachePx(width ?? height, dpr, maxPx: cap),
        quality,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final logical = w.isFinite
            ? w
            : (h.isFinite ? h : null);
        return _paint(
          oraclyDecodeCachePx(logical, dpr, maxPx: cap),
          quality,
        );
      },
    );
  }

  Widget _paint(int? cacheWidth, FilterQuality quality) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      alignment: alignment,
      filterQuality: quality,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      errorBuilder: (context, error, stackTrace) {
        final retry = fallbackAsset;
        if (retry != null && retry != assetPath) {
          return Image.asset(
            retry,
            width: width,
            height: height,
            fit: fit,
            color: color,
            alignment: alignment,
            filterQuality: quality,
            gaplessPlayback: true,
            cacheWidth: cacheWidth,
            errorBuilder: (context, error, stackTrace) {
              return fallback ?? const SizedBox.shrink();
            },
          );
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
