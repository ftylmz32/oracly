/// OR-408 — Mystical sanctuary architectural atmosphere (Tarot Home).
library;

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import 'oracly_sacred_identity.dart';

/// Far depth — additional nebula veil for cosmic distance.
class OraclyFarNebulaVeilPainter extends CustomPainter {
  const OraclyFarNebulaVeilPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final drift = sin(phase * pi * 2) * 0.015;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0.15 + drift, -0.35),
          radius: 1.4,
          colors: [
            OraclySacredPalette.purpleEnergy.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(-0.2 - drift, 0.55),
          radius: 1.2,
          colors: [
            OraclySacredPalette.deepViolet.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant OraclyFarNebulaVeilPainter old) =>
      old.phase != phase;
}

/// Middle depth — obsidian columns, floating arches, celestial silhouettes.
class OraclyArchitecturalSilhouettesPainter extends CustomPainter {
  const OraclyArchitecturalSilhouettesPainter({
    required this.phase,
    this.scrollOffset = 0,
  });

  final double phase;
  final double scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final parallax = scrollOffset * 0.08;
    final breathe = sin(phase * pi * 2) * 2;

    _paintColumn(
      canvas,
      size,
      x: size.width * 0.10,
      parallax: parallax,
      breathe: breathe,
    );
    _paintColumn(
      canvas,
      size,
      x: size.width * 0.90,
      parallax: parallax,
      breathe: breathe,
    );

    _paintFloatingArch(canvas, size, y: size.height * 0.12 - parallax * 0.15);
    _paintFloatingArch(
      canvas,
      size,
      y: size.height * 0.42 - parallax * 0.25,
      widthFactor: 0.72,
      alpha: 0.035,
    );
    _paintObsidianLedge(canvas, size, parallax: parallax);
    _paintEngravedGeometry(canvas, size, parallax: parallax);
  }

  void _paintColumn(
    Canvas canvas,
    Size size, {
    required double x,
    required double parallax,
    required double breathe,
  }) {
    final top = size.height * 0.06 - parallax + breathe;
    final height = size.height * 0.78;
    final width = size.width * 0.018;

    final rect = Rect.fromLTWH(x - width / 2, top, width, height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OraclySacredPalette.champagne.withValues(alpha: 0.05),
            OraclySacredPalette.obsidian.withValues(alpha: 0.14),
            OraclySacredPalette.obsidian.withValues(alpha: 0.06),
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(rect),
    );

    canvas.drawLine(
      Offset(x, top),
      Offset(x, top + height),
      Paint()
        ..strokeWidth = 0.35
        ..color = OraclySacredPalette.goldHairline(0.05),
    );
  }

  void _paintFloatingArch(
    Canvas canvas,
    Size size, {
    required double y,
    double widthFactor = 0.58,
    double alpha = 0.032,
  }) {
    final cx = size.width / 2;
    final span = size.width * widthFactor;
    final path = Path()
      ..moveTo(cx - span / 2, y + 18)
      ..quadraticBezierTo(cx, y - 28, cx + span / 2, y + 18);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.45
        ..color = OraclySacredPalette.goldEngrave(alpha),
    );
  }

  void _paintObsidianLedge(Canvas canvas, Size size, {required double parallax}) {
    final y = size.height * 0.88 + parallax * 0.1;
    canvas.drawLine(
      Offset(size.width * 0.08, y),
      Offset(size.width * 0.92, y),
      Paint()
        ..strokeWidth = 0.5
        ..color = OraclySacredPalette.obsidian.withValues(alpha: 0.22),
    );
    canvas.drawLine(
      Offset(size.width * 0.12, y + 1),
      Offset(size.width * 0.88, y + 1),
      Paint()
        ..strokeWidth = 0.35
        ..color = OraclySacredPalette.goldHairline(0.06),
    );
  }

  void _paintEngravedGeometry(Canvas canvas, Size size, {required double parallax}) {
    final cx = size.width / 2;
    final cy = size.height * 0.62 + parallax * 0.12;

    final tri = Path()
      ..moveTo(cx, cy - 14)
      ..lineTo(cx - 12, cy + 8)
      ..lineTo(cx + 12, cy + 8)
      ..close();
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35
        ..color = OraclySacredPalette.goldEngrave(0.05),
    );
  }

  @override
  bool shouldRepaint(covariant OraclyArchitecturalSilhouettesPainter old) =>
      old.phase != phase || old.scrollOffset != scrollOffset;
}

/// Sacred observatory floor — concentric engravings at chamber base.
class OraclySacredFloorPatternPainter extends CustomPainter {
  const OraclySacredFloorPatternPainter({
    required this.phase,
    this.scrollOffset = 0,
  });

  final double phase;
  final double scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.94 + scrollOffset * 0.05;
    final pulse = 1 + sin(phase * pi * 2) * 0.012;

    for (var i = 1; i <= 4; i++) {
      final r = (28.0 + i * 22) * pulse;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.35
          ..color = OraclySacredPalette.goldHairline(0.05 + i * 0.008),
      );
    }

    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4 + phase * 0.08;
      canvas.drawLine(
        Offset(cx + cos(a) * 24, cy + sin(a) * 8),
        Offset(cx + cos(a) * 110, cy + sin(a) * 28),
        Paint()
          ..strokeWidth = 0.3
          ..color = OraclySacredPalette.goldHairline(0.04),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OraclySacredFloorPatternPainter old) =>
      old.phase != phase || old.scrollOffset != scrollOffset;
}

/// Near depth — tiny crystal reflection glints.
class OraclyCrystalReflectionPainter extends CustomPainter {
  const OraclyCrystalReflectionPainter({required this.phase});

  final double phase;

  static const _glints = <(double x, double y, double w)>[
    (0.22, 0.28, 18.0),
    (0.78, 0.22, 14.0),
    (0.68, 0.58, 20.0),
    (0.32, 0.72, 16.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _glints.length; i++) {
      final (x, y, w) = _glints[i];
      final shimmer = 0.5 + sin(phase * pi * 2 + i * 1.7) * 0.5;
      final ox = size.width * x;
      final oy = size.height * y;

      canvas.drawLine(
        Offset(ox - w / 2, oy),
        Offset(ox + w / 2, oy),
        Paint()
          ..strokeWidth = 0.4
          ..color = OraclySacredPalette.champagne.withValues(alpha: 0.04 * shimmer),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OraclyCrystalReflectionPainter old) =>
      old.phase != phase;
}

/// Primary orb light shaft — warm above, violet below, scroll-aware.
class OraclyOrbLightShaftPainter extends CustomPainter {
  const OraclyOrbLightShaftPainter({
    required this.phase,
    this.scrollOffset = 0,
  });

  final double phase;
  final double scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final warmPulse = 0.07 + sin(phase * pi * 2) * 0.012;
    final topCenter = Offset(
      size.width / 2,
      -scrollOffset * 0.12,
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            0,
            -0.75 + scrollOffset * 0.00008,
          ),
          radius: 1.35,
          colors: [
            OraclySacredPalette.champagne.withValues(alpha: warmPulse * 1.15),
            OraclySacredPalette.purpleEnergySoft.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.38, 0.82],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawLine(
      topCenter,
      Offset(size.width / 2, size.height),
      Paint()
        ..strokeWidth = 0.5
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OraclySacredPalette.champagne.withValues(alpha: 0.10),
            OraclySacredPalette.purpleEnergy.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant OraclyOrbLightShaftPainter old) =>
      old.phase != phase || old.scrollOffset != scrollOffset;
}

/// Scroll immersion veil — softens section edges, deepens lower chamber.
class OraclyScrollChamberVeilPainter extends CustomPainter {
  const OraclyScrollChamberVeilPainter({required this.scrollOffset});

  final double scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final depth = (scrollOffset * 0.00005).clamp(0.0, 0.12);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            OraclySacredPalette.obsidian.withValues(alpha: 0.04 + depth),
            OraclySacredPalette.deepViolet.withValues(alpha: 0.06 + depth * 0.5),
          ],
          stops: const [0.0, 0.35, 0.78, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant OraclyScrollChamberVeilPainter old) =>
      old.scrollOffset != scrollOffset;
}
