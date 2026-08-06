/// OR-401 / OR-406 — Sacred spread mini-illustrations for selection cards.
library;

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import 'oracly_sacred_identity.dart';
import 'spread_card_living.dart';
import 'spread_sacred_identity.dart';
import 'tarot_atmosphere.dart';

/// Visual personality for each spread type.
enum SpreadVisualStyle {
  single,
  threeCard,
  fiveCard,
  celticCross,
}

/// Ritual layout preview — illustration-first hierarchy.
class SpreadLayoutPreview extends StatelessWidget {
  const SpreadLayoutPreview({
    super.key,
    required this.style,
    this.active = false,
    this.breathPhase = 0,
    this.ambientPhase = 0,
  });

  final SpreadVisualStyle style;
  final bool active;
  final double breathPhase;
  final double ambientPhase;

  static const double width = 152;
  static const double height = 108;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SpreadLayoutPainter(
          style: style,
          active: active,
          breathPhase: breathPhase,
          ambientPhase: ambientPhase,
        ),
      ),
    );
  }
}

class _SpreadLayoutPainter extends CustomPainter {
  const _SpreadLayoutPainter({
    required this.style,
    required this.active,
    required this.breathPhase,
    this.ambientPhase = 0,
  });

  final SpreadVisualStyle style;
  final bool active;
  final double breathPhase;
  final double ambientPhase;

  @override
  void paint(Canvas canvas, Size size) {
    _paintEmotionalWash(canvas, size);
    switch (style) {
      case SpreadVisualStyle.single:
        _paintSingle(canvas, size);
      case SpreadVisualStyle.threeCard:
        _paintThreeCard(canvas, size);
      case SpreadVisualStyle.fiveCard:
        _paintFiveCard(canvas, size);
      case SpreadVisualStyle.celticCross:
        _paintCelticCross(canvas, size);
    }
  }

  void _paintEmotionalWash(Canvas canvas, Size size) {
    final identity = TarotAtmosphere.identity(style);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.15),
          radius: 0.95,
          colors: [
            identity.accent.withValues(alpha: active ? 0.11 : 0.07),
            identity.accentSoft.withValues(alpha: active ? 0.06 : 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );
  }

  void _paintSingle(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final pulse = active ? 0.06 + breathPhase * 0.03 : 0.03;
    final identity = TarotAtmosphere.identity(SpreadVisualStyle.single);

    // One focused beam — quiet, minimal.
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy - 8), width: 6, height: size.height * 0.55),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            identity.accent.withValues(alpha: 0.12),
            identity.accentSoft.withValues(alpha: 0.04),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawCircle(
      Offset(cx, cy),
      34,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = OraclySacredPalette.purpleEnergy.withValues(alpha: pulse * 0.85),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      28,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.4
        ..color = OraclySacredPalette.goldEngrave(active ? 0.26 : 0.14),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      38,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.25
        ..color = TarotAtmosphere.identity(SpreadVisualStyle.single)
            .accentSoft
            .withValues(alpha: active ? 0.18 : 0.10),
    );

    _drawTarotCard(
      canvas,
      center: Offset(cx, cy),
      width: 44,
      height: 66,
      glow: active,
      elevation: 0,
    );
  }

  void _paintThreeCard(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 2;
    final triAccent = TarotAtmosphere.identity(SpreadVisualStyle.threeCard).accent;

    // Three harmonious light sources.
    for (final dx in [-22.0, 0.0, 22.0]) {
      canvas.drawCircle(
        Offset(cx + dx, cy - (dx == 0 ? 4 : 2)),
        10,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
          ..color = triAccent.withValues(
            alpha: 0.05 + sin(ambientPhase * pi * 2 + dx) * 0.015,
          ),
      );
    }

    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + 8), width: 72, height: 28),
      pi * 1.08,
      pi * 0.84,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.3
        ..color = triAccent.withValues(alpha: active ? 0.16 : 0.09),
    );
    // Symmetric triangular composition.
    final triPath = Path()
      ..moveTo(cx - 22, cy + 4)
      ..lineTo(cx, cy - 8)
      ..lineTo(cx + 22, cy + 4)
      ..close();
    canvas.drawPath(
      triPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.25
        ..color = OraclySacredPalette.goldHairline(active ? 0.12 : 0.07),
    );

    _drawTarotCard(
      canvas,
      center: Offset(cx - 22, cy + 2),
      width: 30,
      height: 46,
      rotation: -0.14,
      opacity: 0.76,
      elevation: 0,
    );
    _drawTarotCard(
      canvas,
      center: Offset(cx + 22, cy + 2),
      width: 30,
      height: 46,
      rotation: 0.14,
      opacity: 0.76,
      elevation: 0,
    );
    if (active) {
      canvas.drawCircle(
        Offset(cx, cy),
        22,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
          ..color = OraclySacredPalette.champagne
              .withValues(alpha: 0.06 + breathPhase * 0.03),
      );
    }
    _drawTarotCard(
      canvas,
      center: Offset(cx, cy - 4),
      width: 34,
      height: 52,
      glow: active,
      elevation: 2,
    );
  }

  void _paintFiveCard(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final fiveIdentity = TarotAtmosphere.identity(SpreadVisualStyle.fiveCard);
    final mysticPulse = 0.88 + sin(ambientPhase * pi * 2) * 0.12;

    canvas.drawCircle(
      Offset(cx, cy - 8),
      36 * mysticPulse,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color = fiveIdentity.accent.withValues(alpha: active ? 0.10 : 0.07),
    );

    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 6), width: 108, height: 44),
      pi * 1.05,
      pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.45
        ..color = OraclySacredPalette.goldEngrave(active ? 0.24 : 0.14),
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 6), width: 118, height: 50),
      pi * 1.05,
      pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.25
        ..color = TarotAtmosphere.identity(SpreadVisualStyle.fiveCard)
            .accent
            .withValues(alpha: active ? 0.14 : 0.08),
    );

    const cardW = 20.0;
    const cardH = 32.0;
    const angles = [-0.28, -0.14, 0.0, 0.14, 0.28];
    const lifts = [6.0, 10.0, 14.0, 10.0, 6.0];
    final sacred = SpreadSacredIdentity.profile(SpreadVisualStyle.fiveCard);

    // Journey path — longer decorative arc.
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 120 * sacred.lineLength, height: 36),
      pi * 1.02,
      pi * 0.96,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.28
        ..color = fiveIdentity.accentSoft.withValues(alpha: active ? 0.14 : 0.08),
    );

    for (var i = 0; i < 5; i++) {
      final a = angles[i];
      final x = cx + sin(a) * 38;
      final y = cy - lifts[i];
      _drawTarotCard(
        canvas,
        center: Offset(x, y),
        width: cardW,
        height: cardH,
        rotation: a * 0.85,
        glow: i == 2 && active,
        elevation: i == 2 ? 2 : 0,
        opacity: i == 2 ? 1.0 : 0.80,
      );
    }
  }

  void _paintCelticCross(Canvas canvas, Size size) {
    final cx = size.width / 2 - 4;
    final cy = size.height / 2;

    final geo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45
      ..color = OraclySacredPalette.goldEngrave(active ? 0.28 : 0.16);

    final ancient = SpreadCardLiving.profile(SpreadVisualStyle.celticCross);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            OraclySacredPalette.champagneShadow.withValues(alpha: 0.05),
            Colors.transparent,
            OraclySacredPalette.obsidian.withValues(alpha: 0.08),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawCircle(Offset(cx, cy), 34, geo);
    canvas.drawCircle(Offset(cx, cy), 22, geo);
    canvas.drawCircle(
      Offset(cx, cy),
      40,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.3
        ..color = OraclySacredPalette.goldEngrave(
          ancient.goldEngrave * (active ? 0.85 : 0.55),
        ),
    );
    for (var i = 0; i < 4; i++) {
      final a = i * pi / 2 + pi / 4;
      canvas.drawLine(
        Offset(cx + cos(a) * 10, cy + sin(a) * 10),
        Offset(cx + cos(a) * 36, cy + sin(a) * 36),
        geo,
      );
    }
    // Subtle runic ticks — ancient, never flashy.
    final runeX = size.width * 0.08;
    final runeY = size.height * 0.88;
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(runeX + i * 4.5, runeY - 5),
        Offset(runeX + i * 4.5, runeY + 1),
        Paint()
          ..strokeWidth = 0.28
          ..color = OraclySacredPalette.goldEngrave(active ? 0.18 : 0.10),
      );
    }

    _drawTarotCard(canvas, center: Offset(cx, cy - 26), width: 16, height: 24, elevation: 0);
    _drawTarotCard(canvas, center: Offset(cx, cy + 26), width: 16, height: 24, elevation: 0);
    _drawTarotCard(canvas, center: Offset(cx - 24, cy), width: 16, height: 24, elevation: 0);
    _drawTarotCard(canvas, center: Offset(cx + 24, cy), width: 16, height: 24, elevation: 0);
    _drawTarotCard(
      canvas,
      center: Offset(cx, cy),
      width: 22,
      height: 32,
      glow: active,
      elevation: 2,
    );
    _drawTarotCard(
      canvas,
      center: Offset(cx, cy),
      width: 18,
      height: 26,
      rotation: pi / 2,
      opacity: 0.70,
      elevation: 1,
    );
    _drawTarotCard(
      canvas,
      center: Offset(cx + 38, cy + 18),
      width: 14,
      height: 20,
      opacity: 0.72,
      elevation: 0,
    );
  }

  void _drawTarotCard(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    double rotation = 0,
    bool glow = false,
    int elevation = 0,
    double opacity = 1,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final rect = Rect.fromCenter(center: Offset.zero, width: width, height: height);
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(3.5));

    if (elevation > 0) {
      canvas.drawRRect(
        r.shift(const Offset(0, 1.5)),
        Paint()
          ..color = OraclySacredPalette.obsidian.withValues(alpha: 0.22 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    if (glow && active) {
      canvas.drawRRect(
        r.inflate(2),
        Paint()
          ..color = OraclySacredPalette.champagne
              .withValues(alpha: 0.08 + breathPhase * 0.04)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    canvas.drawRRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OraclySacredPalette.purpleEnergy.withValues(alpha: 0.48 * opacity),
            OraclySacredPalette.crystalVeil.withValues(alpha: 0.88 * opacity),
            OraclySacredPalette.obsidian.withValues(alpha: 0.94 * opacity),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75
        ..color = OraclySacredPalette.champagne
            .withValues(alpha: (glow ? 0.48 : 0.36) * opacity),
    );

    canvas.drawLine(
      Offset(rect.left + 3, rect.top + 4),
      Offset(rect.right - 3, rect.top + 4),
      Paint()
        ..strokeWidth = 0.4
        ..color = Colors.white.withValues(alpha: 0.08 * opacity),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpreadLayoutPainter old) =>
      old.style != style ||
      old.active != active ||
      old.breathPhase != breathPhase ||
      old.ambientPhase != ambientPhase;
}
