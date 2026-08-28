/// Astrology + Yıldızname motifs — glyph wheel / deep archive.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/oracly_brand_signature.dart';

void paintAstrologyMotif(Canvas canvas, Size size) {
  final c = Offset(size.width * 0.54, size.height * 0.4);
  final s = size.shortestSide * 0.26;
  final gold = OraclySignaturePalette.goldEngrave(0.8);
  canvas.drawCircle(
    c,
    s,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = gold,
  );
  canvas.drawCircle(
    c,
    s * 0.72,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55
      ..color = gold.withValues(alpha: 0.45),
  );
  for (var i = 0; i < 12; i++) {
    final a = i * math.pi / 6 - math.pi / 2;
    final inner = c + Offset(math.cos(a) * s * 0.78, math.sin(a) * s * 0.78);
    final outer = c + Offset(math.cos(a) * s * 1.08, math.sin(a) * s * 1.08);
    canvas.drawLine(
      inner,
      outer,
      Paint()
        ..strokeWidth = i % 3 == 0 ? 1.15 : 0.65
        ..color = gold.withValues(alpha: i % 3 == 0 ? 0.9 : 0.45),
    );
    if (i % 3 == 0) {
      canvas.drawCircle(outer, 2.0, Paint()..color = gold);
    }
  }
  // Quiet central glyph — ascending lunar mark.
  final g = Path()
    ..moveTo(c.dx, c.dy - s * 0.28)
    ..quadraticBezierTo(c.dx + s * 0.22, c.dy, c.dx, c.dy + s * 0.28)
    ..quadraticBezierTo(c.dx - s * 0.12, c.dy, c.dx, c.dy - s * 0.28);
  canvas.drawPath(
    g,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..color = gold,
  );
}

void paintStarMapMotif(Canvas canvas, Size size) {
  final c = Offset(size.width * 0.5, size.height * 0.4);
  final gold = OraclySignaturePalette.goldEngrave(0.72);
  for (final r in [0.14, 0.22, 0.32]) {
    canvas.drawCircle(
      c,
      size.width * r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r == 0.14 ? 0.9 : 0.5
        ..color = gold.withValues(alpha: r == 0.14 ? 0.55 : 0.22),
    );
  }
  canvas.drawCircle(c, size.width * 0.05, Paint()..color = gold.withValues(alpha: 0.35));
  final pts = [
    Offset(c.dx - 30, c.dy - 10),
    Offset(c.dx - 8, c.dy - 24),
    Offset(c.dx + 18, c.dy - 16),
    Offset(c.dx + 32, c.dy + 8),
    Offset(c.dx + 6, c.dy + 22),
    Offset(c.dx - 20, c.dy + 14),
  ];
  for (var i = 0; i < pts.length; i++) {
    canvas.drawCircle(pts[i], i.isEven ? 2.6 : 1.8, Paint()..color = gold);
    canvas.drawLine(
      pts[i],
      pts[(i + 1) % pts.length],
      Paint()
        ..strokeWidth = 0.6
        ..color = gold.withValues(alpha: 0.4),
    );
  }
}
