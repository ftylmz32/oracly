/// OR-017 — Premium static cosmic background for the home screen.
library;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/universe/oracly_universe_layer.dart';
import '../../../core/universe/oracly_universe_state.dart';
import '../theme/home_composition.dart';
import '../theme/home_focus.dart';
import '../theme/home_architecture.dart';
import '../theme/home_atmosphere.dart';
import '../theme/home_observatory.dart';
import '../theme/home_presence.dart';

/// Full-screen home wrapper — base gradient, cosmic layers, and content.
class HomeCinematicBackground extends StatelessWidget {
  const HomeCinematicBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.background),
          child: SizedBox.expand(),
        ),
        const HomeCosmicBackground(),
        child,
      ],
    );
  }
}

/// Static cosmic overlay — gold stars, purple nebula, glowing particles.
class HomeCosmicBackground extends StatelessWidget {
  const HomeCosmicBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = HomeFocusScope.maybeOf(context);
    final calm = scope?.worldCalm ?? 1.0;
    final energy = scope?.ambientEnergy ?? 1.0;
    final presence = scope?.presence;
    final scroll = scope?.scrollOffset ?? 0;
    final bgParallax = HomePresenceRhythm.parallaxBackground(scroll);
    final atmParallax = HomePresenceRhythm.parallaxAtmosphere(scroll);
    final universe =
        OraclyUniverseScope.maybeOf(context) ?? OraclyUniverseState.current();
    final env = universe.modulation;

    Widget buildLayers(double phase) {
      final veil = HomePresenceRhythm.ambientVeil(phase);
      final drift = HomePresenceRhythm.nebulaDrift(
        phase,
        amplitude: 2.2 * (0.85 + energy * 0.15),
      );
      final obsPhase = HomeObservatoryTime.channel(0, offset: phase);
      final chamberVeilOpacity =
          env.veilOpacity((0.88 + calm * 0.12) * veil);
      final nebulaFieldOpacity =
          env.atmosphericOpacity(calm.clamp(0.0, 1.0));
      final nebulaNoiseOpacity =
          env.atmosphericOpacity((0.72 + calm * 0.28).clamp(0.0, 1.0));
      final starFieldOpacity =
          env.particleOpacity((0.68 + calm * 0.32).clamp(0.0, 1.0));
      final glowParticleOpacity =
          env.particleOpacity((0.54 + calm * 0.38).clamp(0.0, 1.0));
      final driftOpacity =
          env.particleOpacity((0.42 + calm * 0.45).clamp(0.0, 1.0));
      final travelingLightOpacity =
          env.atmosphericOpacity((0.38 + calm * 0.35).clamp(0.0, 1.0));
      final crystalBreathOpacity =
          env.crystalOpacity((0.55 + calm * 0.3).clamp(0.0, 1.0));
      final shimmerOpacity =
          env.crystalOpacity((0.48 + calm * 0.4).clamp(0.0, 1.0));

      return Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: chamberVeilOpacity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: HomeComposition.orbChamberGlow(phase),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Transform.translate(
            offset: Offset(drift.dx, drift.dy + atmParallax),
            child: _NebulaField(layerOpacity: nebulaFieldOpacity),
          ),
          Transform.translate(
            offset: Offset(0, bgParallax),
            child: CustomPaint(
              painter: _NebulaNoisePainter(layerOpacity: nebulaNoiseOpacity),
            ),
          ),
          CustomPaint(
            painter: _GoldStarFieldPainter(layerOpacity: starFieldOpacity),
          ),
          CustomPaint(
            painter: _GlowParticlePainter(
              phase: phase,
              energy: energy,
              warmthBlend: env.warmthBlendFactor(),
              layerOpacity: glowParticleOpacity,
            ),
          ),
          CustomPaint(
            painter: HomeObservatoryDriftPainter(
              masterPhase: obsPhase,
              energy: energy,
              calm: calm,
              layerOpacity: driftOpacity,
            ),
          ),
          CustomPaint(
            painter: HomeObservatoryTravelingLightPainter(
              phase: obsPhase,
              calm: calm,
              layerOpacity: travelingLightOpacity,
            ),
          ),
          CustomPaint(
            painter: HomeObservatoryCrystalBreathPainter(
              phase: phase,
              layerOpacity: crystalBreathOpacity,
            ),
          ),
          CustomPaint(
            painter: HomeChamberShimmerPainter(
              phase: obsPhase,
              layerOpacity: shimmerOpacity,
            ),
          ),
          Transform.translate(
            offset: Offset(0, bgParallax * 0.6),
            child: CustomPaint(
              painter: HomeChamberArchitecturePainter(
                lightPhase: HomePresenceRhythm.goldSpecular(phase),
              ),
            ),
          ),
          const HomeChamberFloorGradient(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: HomeAtmosphere.lowerChamberCalm,
            ),
            child: const SizedBox.expand(),
          ),
          OraclyUniverseLayer(
            state: universe,
            masterPhase: obsPhase,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.22),
                radius: 1.08,
                colors: [
                  Colors.transparent,
                  Color(0x12000000),
                ],
                stops: [0.62, 1.0],
              ),
            ),
          ),
        ],
      );
    }

    if (presence == null) return buildLayers(HomePresenceRhythm.clockPhase());

    return AnimatedBuilder(
      animation: presence,
      builder: (context, _) => buildLayers(presence.value),
    );
  }
}

class _NebulaField extends StatelessWidget {
  const _NebulaField({this.layerOpacity = 1});

  final double layerOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -88,
          left: -54,
          child: _NebulaOrb(
            size: 360,
            color: HomeAtmosphere.mysteryViolet,
            opacity: 0.085 * layerOpacity,
          ),
        ),
        Positioned(
          top: 168,
          right: -96,
          child: _NebulaOrb(
            size: 300,
            color: HomeAtmosphere.hopefulWarm,
            opacity: 0.055 * layerOpacity,
          ),
        ),
        Positioned(
          bottom: 48,
          left: -28,
          child: _NebulaOrb(
            size: 260,
            color: HomeAtmosphere.coolMist,
            opacity: 0.07 * layerOpacity,
          ),
        ),
      ],
    );
  }
}

class _NebulaOrb extends StatelessWidget {
  const _NebulaOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 96, sigmaY: 96),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _NebulaNoisePainter extends CustomPainter {
  const _NebulaNoisePainter({this.layerOpacity = 1});

  final double layerOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(29);

    for (var i = 0; i < 140; i++) {
      final alpha = (0.05 + random.nextDouble() * 0.05) * layerOpacity;
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * 1.6 + 0.4,
        Paint()..color = AppColors.purpleLight.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NebulaNoisePainter oldDelegate) =>
      oldDelegate.layerOpacity != layerOpacity;
}

class _GoldStarFieldPainter extends CustomPainter {
  const _GoldStarFieldPainter({this.layerOpacity = 1});

  final double layerOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(11);

    for (var i = 0; i < 210; i++) {
      final alpha = (0.05 + random.nextDouble() * 0.07) * layerOpacity;
      final radius = random.nextDouble() * 0.75 + 0.2;
      final useGold = random.nextDouble() > 0.22;

      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        radius,
        Paint()
          ..color = (useGold ? AppColors.goldLight : AppColors.gold)
              .withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldStarFieldPainter oldDelegate) =>
      oldDelegate.layerOpacity != layerOpacity;
}

class _GlowParticlePainter extends CustomPainter {
  const _GlowParticlePainter({
    required this.phase,
    this.energy = 1.0,
    this.warmthBlend = 0.5,
    this.layerOpacity = 1,
  });

  final double phase;
  final double energy;
  final double warmthBlend;
  final double layerOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(53);
    final shimmer = HomeAtmosphere.crystalShimmer(phase);

    for (var i = 0; i < 42; i++) {
      final drift = HomeObservatoryTime.particleOffset(i, phase);
      final base = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final center = base + drift * energy;
      final yNorm = center.dy / size.height;
      final breathe = 0.92 + 0.08 * sin((phase + i * 0.07) * pi * 2);
      final alpha = ((0.04 + random.nextDouble() * 0.06) * breathe * energy +
              shimmer) *
          layerOpacity;
      final radius = random.nextDouble() * 0.9 + 0.35;
      final color = Color.lerp(
        HomeAtmosphere.mysteryViolet,
        HomeAtmosphere.wisdomGold,
        warmthBlend * HomeAtmosphere.particleWarmth(yNorm),
      )!;

      canvas.drawCircle(
        center,
        radius * 2.2,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.42)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      canvas.drawCircle(
        center,
        radius,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlowParticlePainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.energy != energy ||
      oldDelegate.warmthBlend != warmthBlend ||
      oldDelegate.layerOpacity != layerOpacity;
}
