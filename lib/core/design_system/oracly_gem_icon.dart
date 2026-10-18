/// Canonical Oracly gem — the approved violet crystal, any size.
library;

import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// Live gem identity — use everywhere mücevher appears.
class OraclyGemIcon extends StatelessWidget {
  const OraclyGemIcon({
    super.key,
    this.size = 28,
    this.glow = 1,
    this.dimmed = false,
    this.semanticsLabel,
  });

  final double size;
  final double glow;
  final bool dimmed;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final strength = glow.clamp(0.0, 1.0);
    final opacity = dimmed ? 0.62 : 0.9 + (0.1 * strength);
    return Semantics(
      label: semanticsLabel,
      image: semanticsLabel != null,
      child: SizedBox(
        width: size,
        height: size,
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            AppAssets.gemCrystal,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
