/// Bounded review-card thumbnail (Phase 2C2 §9/§33) — file-backed only,
/// decode capped well under the architect's 512 physical-pixel ceiling so
/// three of these can render together without three near-full-resolution
/// decodes.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/performance/oracly_decode_cache.dart';

class CoffeeV2Thumbnail extends StatelessWidget {
  const CoffeeV2Thumbnail({super.key, required this.path});

  final String path;

  /// Logical edge — well under the 512 physical-pixel ceiling even at a
  /// 3x device pixel ratio (480 * 1 = 480 < 512; still <= 512 up to ~1.06x).
  /// `oraclyDecodeCachePx` below caps the PHYSICAL result at [_maxPhysicalPx]
  /// regardless of device pixel ratio, so the ceiling always holds.
  static const _logicalEdge = 200.0;
  static const _maxPhysicalPx = 512;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: OraclyChrome.cardRadius,
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        cacheWidth: oraclyDecodeCachePx(
          _logicalEdge,
          dpr,
          maxPx: _maxPhysicalPx,
        ),
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: OraclyChrome.midnight,
          child: Icon(
            Icons.coffee_outlined,
            color: OraclyChrome.goldLight.withValues(alpha: 0.42),
          ),
        ),
      ),
    );
  }
}
