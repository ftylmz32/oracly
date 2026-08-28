/// OR-999 / EPIC-013 — Production Hero Orb (Home visual centerpiece).
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'orb_constants.dart';
import 'orb_scene.dart';

/// Premium hero orb rendering system matched to the reference blueprint.
///
/// Architecture:
/// - [OrbScene] — animation, cache, repaint boundary, tap pulse
/// - [OrbRenderer] — reference asset + motion overlays
/// - Layer modules — glow, energy rings, particles, shimmer
class HeroOrb extends StatelessWidget {
  const HeroOrb({
    super.key,
    this.size = AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xxl + AppSpacing.lg,
    this.onTap,
  });

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canvasSize = OrbConstants.renderSize(size);

    return SizedBox(
      width: canvasSize,
      height: canvasSize,
      child: OrbScene(layoutSize: size, onTap: onTap),
    );
  }
}
