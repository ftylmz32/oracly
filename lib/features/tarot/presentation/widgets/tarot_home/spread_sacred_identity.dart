/// OR-419 — Sacred Identity System: each reading type is its own ritual.
library;

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import 'oracly_sacred_identity.dart';
import 'spread_visual_style.dart';

/// Canonical emotional + visual identity per spread — read before the title.
abstract final class SpreadSacredIdentity {
  SpreadSacredIdentity._();

  static SacredSpreadProfile profile(SpreadVisualStyle style) =>
      switch (style) {
        SpreadVisualStyle.single => _single,
        SpreadVisualStyle.threeCard => _three,
        SpreadVisualStyle.fiveCard => _five,
        SpreadVisualStyle.celticCross => _celtic,
      };

  static Gradient ambientTint(SpreadVisualStyle style) {
    final p = profile(style);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        p.ambientTint.withValues(alpha: p.ambientAlpha),
        p.ambientTint.withValues(alpha: p.ambientAlpha * 0.65),
        Colors.transparent,
      ],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  static TextStyle titleStyle(SpreadVisualStyle style, {bool selected = false}) {
    final p = profile(style);
    final base = OraclyTypography.tileTitle(fontSize: p.titleSize);
    final selBoost = selected ? 0.06 : 0.0;
    return base.copyWith(
      fontWeight: p.titleWeight,
      letterSpacing: p.titleLetterSpacing,
      height: p.titleHeight,
      color: p.titleColor.withValues(alpha: p.titleOpacity + selBoost),
      shadows: p.titleGoldGlow
          ? [
              Shadow(
                color: OraclySacredPalette.champagneDeep
                    .withValues(alpha: 0.12 + selBoost),
                blurRadius: 6,
              ),
            ]
          : null,
    );
  }

  static TextStyle captionStyle(SpreadVisualStyle style, {bool selected = false}) {
    final p = profile(style);
    return OraclyTypography.captionWhisper(alpha: p.captionOpacity).copyWith(
      letterSpacing: p.captionLetterSpacing,
      height: p.captionHeight,
      fontWeight: p.captionWeight,
    );
  }

  // ── Profiles ───────────────────────────────────────────────────────────────

  /// Clarity · Focus · Stillness — largest silence.
  static const _single = SacredSpreadProfile(
    emotion: SpreadEmotion.clarity,
    ambientTint: Color(0xFF18141E),
    ambientAlpha: 0.035,
    titleWeight: FontWeight.w500,
    titleLetterSpacing: 0.65,
    titleHeight: 1.30,
    titleSize: 13.5,
    titleOpacity: 0.82,
    titleColor: OraclySacredPalette.champagne,
    titleGoldGlow: false,
    captionOpacity: 0.46,
    captionLetterSpacing: 0.32,
    captionHeight: 1.78,
    captionWeight: FontWeight.w400,
    ornamentIntensity: 0.06,
    particleDensity: 0.7,
    lineLength: 0.85,
  );

  /// Balance · Past · Present · Future — harmony.
  static const _three = SacredSpreadProfile(
    emotion: SpreadEmotion.balance,
    ambientTint: Color(0xFF3D2A5E),
    ambientAlpha: 0.048,
    titleWeight: FontWeight.w600,
    titleLetterSpacing: 0.48,
    titleHeight: 1.34,
    titleSize: 13.5,
    titleOpacity: 0.86,
    titleColor: OraclySacredPalette.champagne,
    titleGoldGlow: false,
    captionOpacity: 0.50,
    captionLetterSpacing: 0.30,
    captionHeight: 1.74,
    captionWeight: FontWeight.w400,
    ornamentIntensity: 0.09,
    particleDensity: 0.85,
    lineLength: 1.0,
  );

  /// Exploration · Discovery · Journey — richer mystic.
  static const _five = SacredSpreadProfile(
    emotion: SpreadEmotion.journey,
    ambientTint: Color(0xFF2A3A6E),
    ambientAlpha: 0.055,
    titleWeight: FontWeight.w600,
    titleLetterSpacing: 0.52,
    titleHeight: 1.36,
    titleSize: 13.5,
    titleOpacity: 0.88,
    titleColor: Color(0xFFD8C8F0),
    titleGoldGlow: false,
    captionOpacity: 0.52,
    captionLetterSpacing: 0.28,
    captionHeight: 1.72,
    captionWeight: FontWeight.w400,
    ornamentIntensity: 0.10,
    particleDensity: 1.15,
    lineLength: 1.35,
  );

  /// Ancient wisdom · Sacred ritual — highest prestige.
  static const _celtic = SacredSpreadProfile(
    emotion: SpreadEmotion.ancient,
    ambientTint: Color(0xFF4A3A28),
    ambientAlpha: 0.052,
    titleWeight: FontWeight.w700,
    titleLetterSpacing: 0.58,
    titleHeight: 1.32,
    titleSize: 13.5,
    titleOpacity: 0.90,
    titleColor: OraclySacredPalette.champagneDeep,
    titleGoldGlow: true,
    captionOpacity: 0.48,
    captionLetterSpacing: 0.34,
    captionHeight: 1.76,
    captionWeight: FontWeight.w500,
    ornamentIntensity: 0.14,
    particleDensity: 0.95,
    lineLength: 1.15,
  );
}

enum SpreadEmotion { clarity, balance, journey, ancient }

@immutable
class SacredSpreadProfile {
  const SacredSpreadProfile({
    required this.emotion,
    required this.ambientTint,
    required this.ambientAlpha,
    required this.titleWeight,
    required this.titleLetterSpacing,
    required this.titleHeight,
    required this.titleSize,
    required this.titleOpacity,
    required this.titleColor,
    required this.titleGoldGlow,
    required this.captionOpacity,
    required this.captionLetterSpacing,
    required this.captionHeight,
    required this.captionWeight,
    required this.ornamentIntensity,
    required this.particleDensity,
    required this.lineLength,
  });

  final SpreadEmotion emotion;
  final Color ambientTint;
  final double ambientAlpha;
  final FontWeight titleWeight;
  final double titleLetterSpacing;
  final double titleHeight;
  final double titleSize;
  final double titleOpacity;
  final Color titleColor;
  final bool titleGoldGlow;
  final double captionOpacity;
  final double captionLetterSpacing;
  final double captionHeight;
  final FontWeight captionWeight;
  final double ornamentIntensity;
  final double particleDensity;
  final double lineLength;
}

/// Identity-aware sacred ornament — personality before words.
class SpreadSacredOrnamentPainter extends CustomPainter {
  const SpreadSacredOrnamentPainter({
    required this.style,
    required this.phase,
    this.selected = false,
  });

  final SpreadVisualStyle style;
  final double phase;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final sacred = SpreadSacredIdentity.profile(style);
    final alpha = sacred.ornamentIntensity * (selected ? 1.25 : 1.0);

    switch (style) {
      case SpreadVisualStyle.single:
        _paintMinimal(canvas, size, alpha, phase);
      case SpreadVisualStyle.threeCard:
        _paintTriangular(canvas, size, alpha, phase);
      case SpreadVisualStyle.fiveCard:
        _paintJourneyLines(canvas, size, alpha, phase, sacred.lineLength);
      case SpreadVisualStyle.celticCross:
        _paintRunic(canvas, size, alpha, phase);
    }
  }

  void _paintMinimal(Canvas canvas, Size size, double alpha, double phase) {
    // One quiet mark — stillness, not decoration.
    final cx = size.width * 0.88;
    final cy = size.height * 0.14;
    canvas.drawCircle(
      Offset(cx, cy),
      1.2,
      Paint()
        ..color = OraclySacredPalette.champagne.withValues(alpha: alpha * 0.6),
    );
    canvas.drawLine(
      Offset(cx, cy + 4),
      Offset(cx, cy + 10),
      Paint()
        ..strokeWidth = 0.28
        ..color = OraclySacredPalette.goldHairline(alpha * 0.5),
    );
  }

  void _paintTriangular(Canvas canvas, Size size, double alpha, double phase) {
    final cx = size.width * 0.14;
    final cy = size.height * 0.20;
    const h = 14.0;
    final tri = Path()
      ..moveTo(cx, cy - h * 0.55)
      ..lineTo(cx - h * 0.5, cy + h * 0.45)
      ..lineTo(cx + h * 0.5, cy + h * 0.45)
      ..close();
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.32
        ..color = OraclySacredPalette.goldEngrave(alpha * 0.75),
    );
    for (var i = 0; i < 3; i++) {
      final a = -pi / 2 + i * 2 * pi / 3;
      canvas.drawCircle(
        Offset(cx + cos(a) * 5, cy + sin(a) * 3 + 2),
        0.7,
        Paint()
          ..color = OraclySacredPalette.champagne.withValues(alpha: alpha * 0.55),
      );
    }
  }

  void _paintJourneyLines(
    Canvas canvas,
    Size size,
    double alpha,
    double phase,
    double length,
  ) {
    final cx = size.width * 0.86;
    final cy = size.height * 0.78;
    final span = 14.0 * length;
    for (var i = 0; i < 3; i++) {
      final a = -pi / 2 + i * 0.45 + phase * 0.06;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + cos(a) * span, cy + sin(a) * span * 0.6),
        Paint()
          ..strokeWidth = 0.30
          ..color = OraclySacredPalette.goldHairline(alpha * 0.55),
      );
    }
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: span * 1.6, height: span),
      pi * 0.85,
      pi * 0.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.28
        ..color = OraclySacredPalette.purpleEnergySoft.withValues(alpha: alpha * 0.4),
    );
  }

  void _paintRunic(Canvas canvas, Size size, double alpha, double phase) {
    final cx = size.width * 0.11;
    final cy = size.height * 0.76;
    const runes = [-1, 0, 1, 2];
    for (var i = 0; i < runes.length; i++) {
      final x = cx + runes[i] * 5.5;
      final h = 6.0 + (i % 2) * 2.0;
      canvas.drawLine(
        Offset(x, cy - h),
        Offset(x, cy + 2),
        Paint()
          ..strokeWidth = 0.32
          ..color = OraclySacredPalette.goldEngrave(alpha * 0.85),
      );
      if (i % 2 == 0) {
        canvas.drawLine(
          Offset(x - 2, cy - h * 0.4),
          Offset(x + 2.5, cy - h * 0.55),
          Paint()
            ..strokeWidth = 0.25
            ..color = OraclySacredPalette.goldHairline(alpha * 0.55),
        );
      }
    }
    canvas.drawCircle(
      Offset(cx + 8, cy - 10),
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.28
        ..color = OraclySacredPalette.goldEngrave(alpha * 0.5 + sin(phase * pi * 2) * 0.02),
    );
  }

  @override
  bool shouldRepaint(covariant SpreadSacredOrnamentPainter old) =>
      old.style != style ||
      old.phase != phase ||
      old.selected != selected;
}
