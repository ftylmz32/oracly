/// OR-999 — Home v1.0 compositor (FROZEN).
library;

import 'package:flutter/material.dart';

import 'orb_animation.dart';
import 'layers/orb_base_layer.dart';
import 'layers/orb_bloom_layer.dart';
import 'layers/orb_caustics_layer.dart';
import 'layers/orb_core_glow_layer.dart';
import 'layers/orb_energy_layer.dart';
import 'layers/orb_fog_layer.dart';
import 'layers/orb_glass_layer.dart';
import 'layers/orb_glow_layer.dart';
import 'layers/orb_logo_layer.dart';
import 'layers/orb_particles_layer.dart';
import 'layers/orb_pedestal_layer.dart';

/// Final approved stack — glow behind logo, glass and bloom on top.
class OrbRenderer extends StatelessWidget {
  const OrbRenderer({
    super.key,
    required this.layoutSize,
    required this.canvasSize,
    required this.motion,
    this.overlayIntensity = 1.0,
    this.rewardBoost = 1.0,
  });

  final double layoutSize;
  final double canvasSize;
  final OrbAnimationBundle motion;
  final double overlayIntensity;
  final double rewardBoost;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: canvasSize,
      height: canvasSize,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: OrbBaseLayer(),
            ),
          ),
          OrbFogLayer(layoutSize: layoutSize, canvasSize: canvasSize),
          OrbCoreGlowLayer(
            motion: motion,
            layoutSize: layoutSize,
            canvasSize: canvasSize,
            rewardBoost: rewardBoost,
          ),
          OrbLogoLayer(layoutSize: layoutSize, canvasSize: canvasSize),
          OrbGlassLayer(layoutSize: layoutSize, canvasSize: canvasSize),
          OrbCausticsLayer(layoutSize: layoutSize, canvasSize: canvasSize),
          OrbParticlesLayer(
            motion: motion,
            layoutSize: layoutSize,
            canvasSize: canvasSize,
            intensity: overlayIntensity,
          ),
          OrbEnergyLayer(
            motion: motion,
            layoutSize: layoutSize,
            canvasSize: canvasSize,
            intensity: overlayIntensity * rewardBoost.clamp(1.0, 1.12),
          ),
          OrbPedestalLayer(layoutSize: layoutSize, canvasSize: canvasSize),
          OrbGlowLayer(layoutSize: layoutSize, canvasSize: canvasSize),
          OrbBloomLayer(layoutSize: layoutSize, canvasSize: canvasSize),
        ],
      ),
    );
  }
}
