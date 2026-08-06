/// OR-421 — Living observatory — the universe continues when you look away.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'home_architecture.dart';
import 'home_atmosphere.dart';

/// Desynchronized natural time — never obvious loops.
abstract final class HomeObservatoryTime {
  HomeObservatoryTime._();

  /// Incommensurate periods (ms) — channels never align.
  static const _periods = <int>[
    12000,
    17000,
    23000,
    31000,
    41000,
    53000,
  ];

  static double channel(int id, {double offset = 0.0}) {
    final ms = DateTime.now().millisecondsSinceEpoch.toDouble();
    final period = _periods[id % _periods.length];
    return ((ms / period + offset) % 1.0).clamp(0.0, 1.0);
  }

  static double breathe(int id) {
    final t = channel(id);
    return Curves.easeInOut.transform(t);
  }

  static double drift(int id) =>
      0.5 + 0.5 * sin((channel(id) + id * 0.17) * pi * 2);

  static double shimmer(int id) =>
      0.012 + 0.011 * sin((channel(id, offset: 0.23) + id * 0.09) * pi * 2);

  static Offset particleOffset(int seed, double master) {
    final a = channel(seed) * pi * 2 + seed * 0.7;
    final b = channel(seed + 3, offset: 0.41) * pi * 2;
    return Offset(
      sin(a) * (1.8 + seed * 0.15),
      sin(b) * (1.2 + seed * 0.12),
    );
  }
}

/// World reaction to presence — not interaction, presence.
abstract final class HomeObservatoryPresence {
  HomeObservatoryPresence._();

  static const idleSettleMs = 4200;
  static const scrollVelocityNorm = 720.0;

  /// [0 calm … 1 active] from scroll speed.
  static double scrollEnergy(double velocityPxPerSec) =>
      (velocityPxPerSec / scrollVelocityNorm).clamp(0.0, 1.0);

  /// [0 restless … 1 peaceful] after stillness.
  static double idleCalm(int idleMs) =>
      Curves.easeOutCubic.transform(
        (idleMs / idleSettleMs).clamp(0.0, 1.0),
      );

  /// Composite world calm — interaction focus + idle peace.
  static double worldCalm({
    required double focusCalm,
    required double idleCalm,
  }) =>
      (focusCalm * (0.68 + idleCalm * 0.32)).clamp(0.0, 1.0);

  /// Ambient energy — rises gently while scrolling, settles when idle.
  static double ambientEnergy({
    required double scrollEnergy,
    required double idleCalm,
  }) =>
      (0.58 + scrollEnergy * 0.28 + idleCalm * 0.14).clamp(0.55, 1.0);
}

/// Hero orb light memory — physical spill onto nearby surfaces.
abstract final class HomeObservatoryLight {
  HomeObservatoryLight._();

  static double orbMemoryAlpha({
    required HomeOrbProximity proximity,
    required double worldCalm,
    required double lightPhase,
    int imperfectionSeed = 0,
  }) {
    final base = HomeArchitecture.spillAlpha(proximity);
    final breathe = 0.92 + 0.08 * sin((lightPhase + imperfectionSeed * 0.07) * pi * 2);
    final calm = 0.88 + worldCalm * 0.12;
    return base * breathe * calm;
  }

  static double reflectionVariance(int seed, double phase) =>
      0.94 + 0.06 * sin((phase + seed * 0.13) * pi * 2);
}

/// Micro imperfections — luxury through subtle variation.
abstract final class HomeObservatoryImperfection {
  HomeObservatoryImperfection._();

  static double speckAlpha(int seed, double phase) =>
      (0.06 + (seed % 5) * 0.012) *
      HomeObservatoryLight.reflectionVariance(seed, phase);

  static double nebulaAmplitude(int seed) => 2.0 + (seed % 4) * 0.35;

  static double goldSpecularOffset(int seed) => seed * 0.031;
}

/// Slow drifting atmospheric motes — continuous life.
class HomeObservatoryDriftPainter extends CustomPainter {
  const HomeObservatoryDriftPainter({
    required this.masterPhase,
    required this.energy,
    required this.calm,
    this.layerOpacity = 1,
  });

  final double masterPhase;
  final double energy;
  final double calm;
  final double layerOpacity;

  static const _seeds = <(double x, double y, int id)>[
    (0.18, 0.22, 0),
    (0.42, 0.14, 1),
    (0.68, 0.28, 2),
    (0.24, 0.48, 3),
    (0.56, 0.52, 4),
    (0.78, 0.38, 5),
    (0.34, 0.68, 6),
    (0.62, 0.74, 7),
    (0.48, 0.36, 8),
    (0.12, 0.58, 9),
    (0.86, 0.62, 10),
    (0.52, 0.82, 11),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final strength = (0.65 + energy * 0.35) * (0.72 + calm * 0.28);

    for (final (x, y, id) in _seeds) {
      final drift = HomeObservatoryTime.particleOffset(id, masterPhase);
      final ch = HomeObservatoryTime.channel(id + 2);
      final yNorm = y;
      final warmth = HomeAtmosphere.particleWarmth(yNorm);
      final color = Color.lerp(
        HomeAtmosphere.mysteryViolet,
        HomeAtmosphere.wisdomGold,
        warmth,
      )!;
      final alpha =
          HomeObservatoryImperfection.speckAlpha(id, ch) * strength * layerOpacity;

      canvas.drawCircle(
        Offset(
          size.width * x + drift.dx * energy,
          size.height * y + drift.dy * energy,
        ),
        0.45 + (id % 3) * 0.15,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant HomeObservatoryDriftPainter old) =>
      old.masterPhase != masterPhase ||
      old.energy != energy ||
      old.calm != calm ||
      old.layerOpacity != layerOpacity;
}

/// Soft traveling light — never mechanical, never obvious loop.
class HomeObservatoryTravelingLightPainter extends CustomPainter {
  const HomeObservatoryTravelingLightPainter({
    required this.phase,
    required this.calm,
    this.layerOpacity = 1,
  });

  final double phase;
  final double calm;
  final double layerOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final t = HomeObservatoryTime.channel(2, offset: phase * 0.15);
    final eased = sin(t * pi * 2) * 0.5 + 0.5;
    final band = -0.5 + eased * 1.4;
    final alpha =
        (0.035 + calm * 0.02) * (0.85 + sin(t * pi * 4) * 0.15) * layerOpacity;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(band - 0.4, -0.8),
          end: Alignment(band + 0.4, 1.0),
          colors: [
            Colors.transparent,
            HomeAtmosphere.wisdomGold.withValues(alpha: alpha),
            AppColors.purpleLight.withValues(alpha: alpha * 0.55),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant HomeObservatoryTravelingLightPainter old) =>
      old.phase != phase ||
      old.calm != calm ||
      old.layerOpacity != layerOpacity;
}

/// Crystal breathing veil — ultra-soft chamber respiration.
class HomeObservatoryCrystalBreathPainter extends CustomPainter {
  const HomeObservatoryCrystalBreathPainter({
    required this.phase,
    this.layerOpacity = 1,
  });

  final double phase;
  final double layerOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final breathe = HomeObservatoryTime.breathe(1);
    final cx = size.width * 0.5;
    final cy = size.height * (0.24 + sin(phase * pi * 2) * 0.008);

    canvas.drawCircle(
      Offset(cx, cy),
      size.width * (0.28 + breathe * 0.018),
      Paint()
        ..color = HomeAtmosphere.wisdomGold
            .withValues(alpha: (0.018 + breathe * 0.012) * layerOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 56),
    );
  }

  @override
  bool shouldRepaint(covariant HomeObservatoryCrystalBreathPainter old) =>
      old.phase != phase || old.layerOpacity != layerOpacity;
}
