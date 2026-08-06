/// OR-418 — Living reading cards: altar objects, not buttons.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import 'oracly_sacred_identity.dart';
import 'spread_sacred_identity.dart';
import 'spread_visual_style.dart';
import 'tarot_atmosphere.dart';

/// Per-spread living atmosphere — light personality without layout changes.
abstract final class SpreadCardLiving {
  SpreadCardLiving._();

  static const pressScale = OraclySignatureMotion.pressScale;
  static const glassBlur = 15.5;

  static SpreadLivingProfile profile(SpreadVisualStyle style) =>
      switch (style) {
        SpreadVisualStyle.single => const SpreadLivingProfile(
              mood: SpreadMood.quiet,
              centerWarmth: 0.11,
              cornerDepth: 0.18,
              glassDepth: 0.92,
              starCount: 2,
              goldEngrave: 0.11,
              dustBase: 0.035,
            ),
        SpreadVisualStyle.threeCard => const SpreadLivingProfile(
              mood: SpreadMood.harmony,
              centerWarmth: 0.09,
              cornerDepth: 0.16,
              glassDepth: 0.96,
              starCount: 3,
              goldEngrave: 0.12,
              dustBase: 0.04,
            ),
        SpreadVisualStyle.fiveCard => const SpreadLivingProfile(
              mood: SpreadMood.mystic,
              centerWarmth: 0.13,
              cornerDepth: 0.20,
              glassDepth: 1.04,
              starCount: 4,
              goldEngrave: 0.13,
              dustBase: 0.045,
            ),
        SpreadVisualStyle.celticCross => const SpreadLivingProfile(
              mood: SpreadMood.ancient,
              centerWarmth: 0.10,
              cornerDepth: 0.22,
              glassDepth: 1.08,
              starCount: 5,
              goldEngrave: 0.16,
              dustBase: 0.035,
            ),
      };

  static List<BoxShadow> altarShadows({
    required SpreadVisualStyle style,
    required bool pressed,
    bool selected = false,
    double breathPhase = 0,
    double depthMult = 1.0,
  }) {
    final living = profile(style);
    final identity = TarotAtmosphere.identity(style);
    final compress = pressed ? 0.65 : 1.0;
    final depth = depthMult.clamp(0.75, 1.15);
    final restLift = 4.0 + depth * 3.0;

    return [
      BoxShadow(
        color: OraclySacredPalette.obsidian.withValues(alpha: 0.38 * depth),
        blurRadius: pressed ? 5 : 7,
        offset: Offset(0, pressed ? 1.5 : 2),
        spreadRadius: -3,
      ),
      BoxShadow(
        color: OraclySacredPalette.obsidian.withValues(alpha: 0.52 * living.glassDepth * depth),
        blurRadius: pressed ? 10 : 14 + depth * 2,
        offset: Offset(0, pressed ? 2 : restLift),
        spreadRadius: pressed ? -6 : -5,
      ),
      BoxShadow(
        color: OraclySacredPalette.obsidian.withValues(alpha: 0.22 * depth),
        blurRadius: 3,
        offset: Offset(0, pressed ? 1 : 1.5),
        spreadRadius: -2,
      ),
      if (selected)
        BoxShadow(
          color: identity.accent.withValues(alpha: 0.07 + breathPhase * 0.03),
          blurRadius: 12 * compress,
          spreadRadius: -4,
        ),
    ];
  }
}

enum SpreadMood { quiet, harmony, mystic, ancient }

@immutable
class SpreadLivingProfile {
  const SpreadLivingProfile({
    required this.mood,
    required this.centerWarmth,
    required this.cornerDepth,
    required this.glassDepth,
    required this.starCount,
    required this.goldEngrave,
    required this.dustBase,
  });

  final SpreadMood mood;
  final double centerWarmth;
  final double cornerDepth;
  final double glassDepth;
  final int starCount;
  final double goldEngrave;
  final double dustBase;
}

/// Non-uniform altar lighting — darker corners, warm center, style-specific sources.
class SpreadCardAtmospherePainter extends CustomPainter {
  const SpreadCardAtmospherePainter({
    required this.style,
    required this.phase,
    this.pressed = false,
    this.pressT = 0,
  });

  final SpreadVisualStyle style;
  final double phase;
  final bool pressed;
  final double pressT;

  @override
  void paint(Canvas canvas, Size size) {
    final living = SpreadCardLiving.profile(style);
    final identity = TarotAtmosphere.identity(style);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final warmBoost = pressed ? pressT * 0.04 : 0.0;

    // Corner vignette — never uniform.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.05,
          colors: [
            Colors.transparent,
            OraclySacredPalette.obsidian
                .withValues(alpha: living.cornerDepth * 0.35),
            OraclySacredPalette.obsidian
                .withValues(alpha: living.cornerDepth * 0.55),
          ],
          stops: const [0.42, 0.78, 1.0],
        ).createShader(rect),
    );

    // Warm center pool.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.12),
          radius: 0.72,
          colors: [
            OraclySacredPalette.champagne
                .withValues(alpha: living.centerWarmth + warmBoost),
            identity.accentSoft.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(rect),
    );

    switch (style) {
      case SpreadVisualStyle.single:
        _paintSingleBeam(canvas, size, identity, living, warmBoost);
      case SpreadVisualStyle.threeCard:
        _paintTriadSources(canvas, size, identity, phase, warmBoost);
      case SpreadVisualStyle.fiveCard:
        _paintMysticDepth(canvas, size, identity, phase, warmBoost);
      case SpreadVisualStyle.celticCross:
        _paintAncientGold(canvas, size, living, phase, warmBoost);
    }
  }

  void _paintSingleBeam(
    Canvas canvas,
    Size size,
    SpreadCardIdentity identity,
    SpreadLivingProfile living,
    double warmBoost,
  ) {
    final cx = size.width / 2;
    // Narrow crystal beam — clarity, stillness.
    final beam = Path()
      ..moveTo(cx - 4, 0)
      ..lineTo(cx + 4, 0)
      ..lineTo(cx + 10, size.height * 0.48)
      ..lineTo(cx - 10, size.height * 0.48)
      ..close();

    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            identity.accent.withValues(alpha: 0.10 + warmBoost),
            identity.accentSoft.withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawCircle(
      Offset(cx, size.height * 0.36),
      14,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = identity.accent
            .withValues(alpha: living.centerWarmth * 0.55 + warmBoost),
    );
  }

  void _paintTriadSources(
    Canvas canvas,
    Size size,
    SpreadCardIdentity identity,
    double phase,
    double warmBoost,
  ) {
    const sources = [(-0.22, 0.38), (0.0, 0.32), (0.22, 0.38)];
    final points = <Offset>[];
    for (var i = 0; i < sources.length; i++) {
      final (nx, ny) = sources[i];
      final drift = sin(phase * pi * 2 + i * 1.4) * 0.008;
      final ox = size.width * (0.5 + nx);
      final oy = size.height * ny;
      points.add(Offset(ox, oy));
      canvas.drawCircle(
        Offset(ox, oy),
        14,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..color = identity.accent
              .withValues(alpha: 0.06 + drift + warmBoost * 0.5),
      );
    }
    // Triangular harmony composition.
    final tri = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..close();
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.28
        ..color = OraclySacredPalette.goldHairline(0.08 + warmBoost),
    );
  }

  void _paintMysticDepth(
    Canvas canvas,
    Size size,
    SpreadCardIdentity identity,
    double phase,
    double warmBoost,
  ) {
    final sacred = SpreadSacredIdentity.profile(SpreadVisualStyle.fiveCard);
    final pulse = 0.92 + sin(phase * pi * 2) * 0.08;
    final cx = size.width / 2;
    final cy = size.height * 0.38;
    final span = size.width * 0.48 * sacred.lineLength;

    canvas.drawCircle(
      Offset(cx, cy),
      span * pulse,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..color = identity.accent.withValues(alpha: 0.09 + warmBoost),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.30,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = identity.accentSoft.withValues(alpha: 0.07 * pulse),
    );
    // Journey meridian — longer decorative line.
    canvas.drawLine(
      Offset(cx - span * 0.55, cy + 20),
      Offset(cx + span * 0.55, cy + 20),
      Paint()
        ..strokeWidth = 0.32
        ..color = OraclySacredPalette.goldHairline(0.07 + warmBoost * 0.5),
    );
  }

  void _paintAncientGold(
    Canvas canvas,
    Size size,
    SpreadLivingProfile living,
    double phase,
    double warmBoost,
  ) {
    final sacred = SpreadSacredIdentity.profile(SpreadVisualStyle.celticCross);
    final cx = size.width / 2;
    final cy = size.height * 0.4;
    final breathe = 0.9 + sin(phase * pi * 2) * 0.1;
    final engrave = sacred.ornamentIntensity + living.goldEngrave * 0.35;

    canvas.drawCircle(
      Offset(cx, cy),
      48 * breathe,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.40
        ..color = OraclySacredPalette.goldEngrave(engrave + warmBoost),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      32 * breathe,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.32
        ..color = OraclySacredPalette.goldHairline(engrave * 0.75),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      56 * breathe,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.22
        ..color = OraclySacredPalette.champagneShadow.withValues(alpha: 0.12),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OraclySacredPalette.champagneShadow
                .withValues(alpha: 0.04 + warmBoost * 0.5),
            Colors.transparent,
            OraclySacredPalette.champagneDeep.withValues(alpha: 0.03),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant SpreadCardAtmospherePainter old) =>
      old.style != style ||
      old.phase != phase ||
      old.pressed != pressed ||
      old.pressT != pressT;
}

/// Thick glass — inner shadow, edge highlight, subtle refraction.
class SpreadCardGlassPainter extends CustomPainter {
  const SpreadCardGlassPainter({
    required this.style,
    required this.phase,
    this.pressed = false,
    this.pressT = 0,
  });

  final SpreadVisualStyle style;
  final double phase;
  final bool pressed;
  final double pressT;

  @override
  void paint(Canvas canvas, Size size) {
    final living = SpreadCardLiving.profile(style);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final inset = 1.2 + (pressed ? pressT * 0.8 : 0);

    // Soft carved inner glow — crystal depth, never neon.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(inset + 6),
        const Radius.circular(AppRadius.lgValue - 4),
      ),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.22),
          radius: 0.78,
          colors: [
            OraclySacredPalette.champagne.withValues(alpha: 0.045 * living.glassDepth),
            OraclySacredPalette.purpleEnergySoft.withValues(alpha: 0.022),
            Colors.transparent,
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(rect),
    );

    // Inner shadow — glass feels physically thick.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(inset + 2),
        const Radius.circular(AppRadius.lgValue),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            OraclySacredPalette.obsidian
                .withValues(alpha: 0.14 * living.glassDepth),
            OraclySacredPalette.obsidian
                .withValues(alpha: 0.22 * living.glassDepth),
          ],
          stops: const [0.55, 0.82, 1.0],
        ).createShader(rect),
    );

    // Top edge highlight.
    final edgeAlpha = 0.11 + (pressed ? pressT * 0.10 : 0);
    canvas.drawLine(
      Offset(rect.left + 14, rect.top + 0.6),
      Offset(rect.right - 14, rect.top + 0.6),
      Paint()
        ..strokeWidth = 0.6
        ..color = OraclySacredPalette.champagne.withValues(alpha: edgeAlpha),
    );

    // Refraction facet — almost invisible.
    final shimmer = TarotAtmosphere.microLightDrift(phase);
    canvas.drawLine(
      Offset(rect.left, rect.top + rect.height * 0.14),
      Offset(rect.left + rect.width * 0.32 * shimmer, rect.top),
      Paint()
        ..strokeWidth = 0.35
        ..color = Colors.white.withValues(alpha: 0.018 * living.glassDepth),
    );
    canvas.drawLine(
      Offset(rect.right, rect.top + rect.height * 0.18),
      Offset(rect.right - rect.width * 0.28 * (1 - shimmer), rect.top),
      Paint()
        ..strokeWidth = 0.3
        ..color = OraclySacredPalette.champagne.withValues(alpha: 0.015),
    );
  }

  @override
  bool shouldRepaint(covariant SpreadCardGlassPainter old) =>
      old.style != style ||
      old.phase != phase ||
      old.pressed != pressed ||
      old.pressT != pressT;
}

/// Drifting crystal reflection — restrained, never flashy.
class SpreadCardLivingReflectionPainter extends CustomPainter {
  const SpreadCardLivingReflectionPainter({
    required this.phase,
    this.pressed = false,
    this.pressT = 0,
  });

  final double phase;
  final bool pressed;
  final double pressT;

  @override
  void paint(Canvas canvas, Size size) {
    final drift = TarotAtmosphere.microLightDrift(phase);
    final shift = pressed ? pressT * 6 : 0;
    final y = size.height * (0.08 + drift * 0.04) + shift;
    final w = size.width * (0.22 + drift * 0.08);

    canvas.drawLine(
      Offset(size.width * 0.5 - w, y),
      Offset(size.width * 0.5 + w * 0.6, y + 1),
      Paint()
        ..strokeWidth = 0.45
        ..color = OraclySacredPalette.champagne
            .withValues(alpha: 0.05 + (pressed ? pressT * 0.04 : 0)),
    );
  }

  @override
  bool shouldRepaint(covariant SpreadCardLivingReflectionPainter old) =>
      old.phase != phase || old.pressed != pressed || old.pressT != pressT;
}

/// Small decorative stars — count varies by spread personality.
class SpreadCardAltarStarsPainter extends CustomPainter {
  const SpreadCardAltarStarsPainter({
    required this.style,
    required this.phase,
  });

  final SpreadVisualStyle style;
  final double phase;

  static const _positions = <(double x, double y)>[
    (0.10, 0.14),
    (0.90, 0.12),
    (0.86, 0.74),
    (0.14, 0.80),
    (0.50, 0.10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final living = SpreadCardLiving.profile(style);
    final sacred = SpreadSacredIdentity.profile(style);
    final count = living.starCount;
    for (var i = 0; i < count; i++) {
      final (x, y) = _positions[i];
      final twinkle = 0.7 + sin(phase * pi * 2 + i * 1.8) * 0.3;
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        0.55 + (i % 2) * 0.15,
        Paint()
          ..color = OraclySacredPalette.champagne
              .withValues(alpha: 0.06 * twinkle * sacred.particleDensity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpreadCardAltarStarsPainter old) =>
      old.style != style || old.phase != phase;
}

/// Engraved gold border highlights — catch light on press.
class SpreadCardEngravedBorderPainter extends CustomPainter {
  const SpreadCardEngravedBorderPainter({
    required this.style,
    required this.phase,
    this.pressed = false,
    this.pressT = 0,
    this.selected = false,
  });

  final SpreadVisualStyle style;
  final double phase;
  final bool pressed;
  final double pressT;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final living = SpreadCardLiving.profile(style);
    final sacred = SpreadSacredIdentity.profile(style);
    final base = living.goldEngrave + sacred.ornamentIntensity * 0.35 +
        (selected ? 0.08 : 0);
    final catchLight = pressed ? pressT * 0.14 : sin(phase * pi * 2) * 0.02;
    final alpha = base + catchLight;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
      const Radius.circular(AppRadius.lgValue),
    );

    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.45
        ..color = OraclySacredPalette.goldEngrave(alpha),
    );

    // Inner engraved hairline.
    canvas.drawRRect(
      r.deflate(2.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.25
        ..color = OraclySacredPalette.goldHairline(alpha * 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant SpreadCardEngravedBorderPainter old) =>
      old.style != style ||
      old.phase != phase ||
      old.pressed != pressed ||
      old.pressT != pressT ||
      old.selected != selected;
}
