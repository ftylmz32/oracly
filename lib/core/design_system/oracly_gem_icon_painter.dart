/// Faceted Oracly jewel — violet crystal with restrained gold.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'oracly_chrome.dart';

/// Premium currency mark — readable from 14px to hero sizes.
class OraclyGemIconPainter extends CustomPainter {
  OraclyGemIconPainter({this.glow = 1, this.dimmed = false});

  final double glow;
  final bool dimmed;

  @override
  void paint(Canvas canvas, Size size) {
    final g = glow.clamp(0.0, 1.4);
    final dim = dimmed ? 0.62 : 1.0;
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;

    if (g > 0.05) {
      final aura = Paint()
        ..shader = RadialGradient(
          colors: [
            OraclyChrome.violet.withValues(alpha: 0.28 * g * dim),
            OraclyChrome.goldHighlight.withValues(alpha: 0.10 * g * dim),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.08));
      canvas.drawCircle(c, r * 0.90, aura);
    }

    final body = _jewelPath(c, r * 0.78);
    final bounds = body.getBounds();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFB48CFF).withValues(alpha: 0.96 * dim),
            OraclyChrome.violet.withValues(alpha: 0.94 * dim),
            const Color(0xFF3A1A6A).withValues(alpha: 0.98 * dim),
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(bounds),
    );

    // Crown facet — soft ivory/gold catch-light (not neon).
    final crown = Path()
      ..moveTo(c.dx, c.dy - r * 0.78)
      ..lineTo(c.dx + r * 0.28, c.dy - r * 0.18)
      ..lineTo(c.dx, c.dy - r * 0.02)
      ..lineTo(c.dx - r * 0.28, c.dy - r * 0.18)
      ..close();
    canvas.drawPath(
      crown,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OraclyChrome.goldHighlight.withValues(alpha: 0.55 * dim),
            OraclyChrome.cream.withValues(alpha: 0.18 * dim),
            Colors.transparent,
          ],
        ).createShader(crown.getBounds()),
    );

    // Pavilion depth — quiet violet shadow toward the tip.
    final pavilion = Path()
      ..moveTo(c.dx - r * 0.34, c.dy + r * 0.08)
      ..lineTo(c.dx + r * 0.34, c.dy + r * 0.08)
      ..lineTo(c.dx, c.dy + r * 0.74)
      ..close();
    canvas.drawPath(
      pavilion,
      Paint()
        ..color = const Color(0xFF16081F).withValues(alpha: 0.34 * dim),
    );

    // Inner gold caustic — celestial core, restrained.
    canvas.drawCircle(
      Offset(c.dx, c.dy - r * 0.06),
      r * 0.12,
      Paint()
        ..shader = RadialGradient(
          colors: [
            OraclyChrome.goldLight.withValues(alpha: 0.72 * dim),
            OraclyChrome.violet.withValues(alpha: 0.22 * dim),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset(c.dx, c.dy - r * 0.06),
            radius: r * 0.18,
          ),
        ),
    );

    // Hairline facet guides — gold relationship without clutter.
    final facet = Paint()
      ..color = OraclyChrome.goldPrimary.withValues(alpha: 0.34 * dim)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.45, r * 0.028)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx, c.dy - r * 0.78),
      Offset(c.dx, c.dy + r * 0.74),
      facet,
    );
    canvas.drawLine(
      Offset(c.dx - r * 0.52, c.dy + r * 0.02),
      Offset(c.dx + r * 0.52, c.dy + r * 0.02),
      facet,
    );

    // Outer gold rim — readable at capsule size.
    canvas.drawPath(
      body,
      Paint()
        ..color = OraclyChrome.goldPrimary.withValues(alpha: 0.70 * dim)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, r * 0.058)
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Vertical lozenge jewel — distinctive silhouette at tiny sizes.
  Path _jewelPath(Offset c, double r) {
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.58, c.dy - r * 0.12)
      ..lineTo(c.dx + r * 0.42, c.dy + r * 0.22)
      ..lineTo(c.dx, c.dy + r * 0.95)
      ..lineTo(c.dx - r * 0.42, c.dy + r * 0.22)
      ..lineTo(c.dx - r * 0.58, c.dy - r * 0.12)
      ..close();
  }

  @override
  bool shouldRepaint(covariant OraclyGemIconPainter oldDelegate) {
    return oldDelegate.glow != glow || oldDelegate.dimmed != dimmed;
  }
}
