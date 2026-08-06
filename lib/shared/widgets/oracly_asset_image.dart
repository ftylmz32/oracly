/// OR-006 — Reusable asset image with vector fallback support.
library;

import 'package:flutter/material.dart';

/// Loads [assetPath] via [Image.asset]; renders [fallback] when the asset fails.
class OraclyAssetImage extends StatelessWidget {
  const OraclyAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallback,
    this.color,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;
  final Color? color;
  final Alignment alignment;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = width != null ? (width! * dpr).round() : null;
    final cacheH = height != null ? (height! * dpr).round() : null;

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      alignment: alignment,
      filterQuality: filterQuality,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
      errorBuilder: (context, error, stackTrace) {
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
