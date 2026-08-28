/// Faceted celestial crystal — vector gem identity for Oracly.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'oracly_chrome.dart';

class OraclyGemIconPainter extends CustomPainter {
  OraclyGemIconPainter({this.glow = 1, this.dimmed = false});

  final double glow;
  final bool dimmed;

  @override
  void paint(Canvas canvas, Size size) {
    final g = glow.clamp(0.0, 1.4);
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;
    if (g > 0.05) {
      final aura = Paint()
        ..shader = RadialGradient(
          colors: [
            OraclyChrome.violet.withValues(alpha: 0.38 * g),
            OraclyChrome.goldHighlight.withValues(alpha: 0.12 * g),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.1));
      canvas.drawCircle(center, r * 0.92, aura);
    }
    final body = _crystalPath(center, r * 0.78);
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          OraclyChrome.violet.withValues(alpha: dimmed ? 0.55 : 0.92),
          const Color(0xFF5F2BD8).withValues(alpha: dimmed ? 0.5 : 0.88),
          const Color(0xFF2F1A44).withValues(alpha: dimmed ? 0.55 : 0.95),
        ],
      ).createShader(body.getBounds());
    canvas.drawPath(body, fill);
    final highlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          OraclyChrome.goldHighlight.withValues(alpha: dimmed ? 0.2 : 0.55),
          OraclyChrome.goldMuted.withValues(alpha: dimmed ? 0.08 : 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromLTWH(center.dx - r, center.dy - r, r * 2, r * 2));
    canvas.drawRect(Rect.fromLTWH(center.dx - r, center.dy - r, r * 2, r * 2), highlight);
    final core = Paint()
      ..shader = RadialGradient(
        colors: [
          OraclyChrome.goldLight.withValues(alpha: dimmed ? 0.25 : 0.75),
          OraclyChrome.violet.withValues(alpha: dimmed ? 0.2 : 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.44, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.22));
    canvas.drawCircle(center, r * 0.14, core);
    canvas.drawPath(
      body,
      Paint()
        ..color = OraclyChrome.goldPrimary.withValues(alpha: dimmed ? 0.28 : 0.62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, r * 0.055),
    );
  }

  Path _crystalPath(Offset c, double r) {
    final top = Offset(c.dx, c.dy - r);
    final bottom = Offset(c.dx, c.dy + r * 0.92);
    final left = Offset(c.dx - r * 0.72, c.dy + r * 0.08);
    final right = Offset(c.dx + r * 0.72, c.dy + r * 0.08);
    final midL = Offset(c.dx - r * 0.34, c.dy - r * 0.12);
    final midR = Offset(c.dx + r * 0.34, c.dy - r * 0.12);
    return Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(midR.dx, midR.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(midL.dx, midL.dy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant OraclyGemIconPainter oldDelegate) {
    return oldDelegate.glow != glow || oldDelegate.dimmed != dimmed;
  }
}