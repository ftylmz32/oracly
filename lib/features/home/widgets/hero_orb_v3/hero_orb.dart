/// OR-999 — Production Hero Orb (Home v1.0 FROZEN).
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'orb_constants.dart';
import 'orb_scene.dart';

/// Premium hero orb rendering system matched to the reference blueprint.
///
/// Architecture:
/// - [OrbScene] — animation, cache, repaint boundary
/// - [OrbRenderer] — reference asset + motion overlays
/// - Layer modules — glow, energy rings, particles
class HeroOrb extends StatelessWidget {
  const HeroOrb({
    super.key,
    this.size = AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xxl + AppSpacing.lg,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final canvasSize = OrbConstants.renderSize(size);

    return SizedBox(
      width: canvasSize,
      height: canvasSize,
      child: OrbScene(layoutSize: size),
    );
  }
}
