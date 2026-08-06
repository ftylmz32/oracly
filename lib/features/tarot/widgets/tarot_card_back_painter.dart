/// OR-426 — Artifact tarot card back — ancient, embossed, unmistakably ORACLY.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/oracly_brand_signature.dart';

/// Celestial engraved back — static craftsmanship, no looping shine.
class TarotCardBackPainter extends CustomPainter {
  const TarotCardBackPainter({
    this.lightBiasX = 0,
    this.lightBiasY = 0,
  });

  /// Subtle ambient shift as the card moves in space (-0.2 … 0.2).
  final double lightBiasX;
  final double lightBiasY;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2 + lightBiasX * w * 0.04;
    final cy = h * 0.48 + lightBiasY * h * 0.03;

    _crystalVeil(canvas, size, cx, cy);
    _embossedBorder(canvas, size);
    _constellationFragment(canvas, Offset(cx, cy - h * 0.06), w);
    _vesicaCompass(canvas, Offset(cx, h * 0.14), w);
    _celestialGeometry(canvas, Offset(cx, cy), w);
    _centerEmblem(canvas, Offset(cx, cy), w);
    _crystalFacets(canvas, size, lightBiasX, lightBiasY);
    _edgeWear(canvas, size);
    _artifactDust(canvas, size);
  }

  void _crystalVeil(Canvas canvas, Size size, double cx, double cy) {
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.34,
      Paint()
        ..shader = RadialGradient(
          colors: [
            OraclySignaturePalette.purpleEnergy.withValues(alpha: 0.07),
            OraclySignaturePalette.deepViolet.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.34)),
    );
  }

  void _embossedBorder(Canvas canvas, Size size) {
    final inset = size.shortestSide * 0.07;
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
      Radius.circular(inset * 0.55),
    );
    final inner = outer.deflate(inset * 0.45);

    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.65
        ..color = OraclySignaturePalette.goldEngrave(0.42),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35
        ..color = OraclySignaturePalette.goldHairline(0.22),
    );

    for (var i = 0; i < 4; i++) {
      final corner = [
        Offset(inset + 2, inset + 2),
        Offset(size.width - inset - 2, inset + 2),
        Offset(size.width - inset - 2, size.height - inset - 2),
        Offset(inset + 2, size.height - inset - 2),
      ][i];
      canvas.drawCircle(
        corner,
        1.1,
        Paint()..color = OraclySignaturePalette.champagne.withValues(alpha: 0.38),
      );
    }
  }

  void _vesicaCompass(Canvas canvas, Offset center, double w) {
    final vesica = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.38
      ..color = OraclySignaturePalette.goldEngrave(OraclySignatureMotifs.vesicaAlpha);
    canvas.drawCircle(Offset(center.dx - w * 0.028, center.dy), w * 0.045, vesica);
    canvas.drawCircle(Offset(center.dx + w * 0.028, center.dy), w * 0.045, vesica);

    final tri = Path()
      ..moveTo(center.dx, center.dy - w * 0.038)
      ..lineTo(center.dx - w * 0.032, center.dy + w * 0.022)
      ..lineTo(center.dx + w * 0.032, center.dy + w * 0.022)
      ..close();
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.32
        ..color = OraclySignaturePalette.goldEngrave(OraclySignatureMotifs.vesicaTriadAlpha),
    );

    canvas.drawCircle(
      Offset(center.dx, center.dy + w * 0.004),
      0.75,
      Paint()..color = OraclySignaturePalette.purpleEnergy.withValues(alpha: 0.35),
    );
  }

  void _constellationFragment(Canvas canvas, Offset origin, double w) {
    const nodes = [(-0.14, 0), (0, -0.06), (0.14, 0.02)];
    final pts = nodes.map((n) => origin + Offset(n.$1 * w, n.$2 * w)).toList();
    final line = Paint()
      ..strokeWidth = 0.32
      ..color = OraclySignaturePalette.goldHairline(0.18);
    for (var i = 0; i < pts.length - 1; i++) {
      canvas.drawLine(pts[i], pts[i + 1], line);
    }
    for (final p in pts) {
      canvas.drawCircle(
        p,
        0.65,
        Paint()..color = OraclySignaturePalette.champagne.withValues(alpha: 0.32),
      );
    }
  }

  void _celestialGeometry(Canvas canvas, Offset c, double w) {
    for (var ring = 1; ring <= 2; ring++) {
      canvas.drawCircle(
        c,
        w * 0.09 * ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.32
          ..color = OraclySignaturePalette.goldEngrave(0.14 + ring * 0.04),
      );
    }
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        c + Offset(math.cos(a) * w * 0.10, math.sin(a) * w * 0.10),
        c + Offset(math.cos(a) * w * 0.22, math.sin(a) * w * 0.22),
        Paint()
          ..strokeWidth = 0.28
          ..color = OraclySignaturePalette.goldHairline(0.16),
      );
    }
  }

  void _centerEmblem(Canvas canvas, Offset c, double w) {
    canvas.drawCircle(
      c,
      w * 0.095,
      Paint()..color = OraclySignaturePalette.champagne.withValues(alpha: 0.08),
    );
    canvas.drawCircle(
      c,
      w * 0.095,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.55
        ..color = OraclySignaturePalette.goldEngrave(0.48),
    );
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawLine(
        c + Offset(math.cos(a) * w * 0.038, math.sin(a) * w * 0.038),
        c + Offset(math.cos(a) * w * 0.072, math.sin(a) * w * 0.072),
        Paint()
          ..strokeWidth = 0.45
          ..color = OraclySignaturePalette.champagne.withValues(alpha: 0.55),
      );
    }
    canvas.drawCircle(
      c,
      1.4,
      Paint()..color = OraclySignaturePalette.champagne.withValues(alpha: 0.82),
    );
  }

  void _crystalFacets(Canvas canvas, Size size, double bx, double by) {
    final facet = Paint()
      ..strokeWidth = 0.28
      ..style = PaintingStyle.stroke
      ..color = OraclySignaturePalette.champagne.withValues(
        alpha: OraclySignatureMotifs.crystalFacetAlpha,
      );
    final ox = bx * size.width * 0.02;
    final oy = by * size.height * 0.02;
    canvas.drawLine(
      Offset(ox, size.height * 0.14 + oy),
      Offset(size.width * 0.32 + ox, oy),
      facet,
    );
    canvas.drawLine(
      Offset(size.width + ox, size.height * 0.18 + oy),
      Offset(size.width * 0.68 + ox, oy),
      facet,
    );
  }

  void _edgeWear(Canvas canvas, Size size) {
    const seeds = <(double x, double y, double len, double a)>[
      (0.06, 0.04, 4.5, 0.4),
      (0.94, 0.05, 3.8, 2.6),
      (0.05, 0.96, 4.2, -0.5),
      (0.95, 0.94, 3.5, 2.2),
    ];
    final wear = Paint()
      ..strokeWidth = 0.22
      ..color = OraclySignaturePalette.champagneShadow.withValues(alpha: 0.12);
    for (final (x, y, len, a) in seeds) {
      final o = Offset(size.width * x, size.height * y);
      canvas.drawLine(
        o,
        o + Offset(math.cos(a) * len, math.sin(a) * len),
        wear,
      );
    }
  }

  void _artifactDust(Canvas canvas, Size size) {
    for (var i = 0; i < 9; i++) {
      final seed = i * 13 + 5;
      final bx = _pseudo(seed) * size.width;
      final by = _pseudo(seed + 3) * size.height;
      final dot = 0.35 + _pseudo(seed + 9) * 0.35;
      canvas.drawCircle(
        Offset(bx, by),
        dot,
        Paint()
          ..color = OraclySignaturePalette.champagne.withValues(
            alpha: 0.06 + _pseudo(seed + 11) * 0.05,
          ),
      );
    }
  }

  double _pseudo(int seed) {
    final x = math.sin(seed * 12.9898) * 43758.5453;
    return x - x.floor();
  }

  @override
  bool shouldRepaint(covariant TarotCardBackPainter old) =>
      old.lightBiasX != lightBiasX || old.lightBiasY != lightBiasY;
}
