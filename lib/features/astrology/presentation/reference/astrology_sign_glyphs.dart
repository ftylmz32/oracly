/// Symbolic gold glyphs per tropical sign — artwork only, not a sky map.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

abstract final class AstrologySignGlyphs {
  AstrologySignGlyphs._();

  static void paint(
    Canvas canvas,
    String id,
    Offset c,
    double r, {
    double alpha = 0.94,
    Color? color,
  }) {
    final stroke = Paint()
      ..color = (color ?? OraclyChrome.goldLight).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (id) {
      case 'taurus':
        _taurus(canvas, c, r, stroke);
      case 'gemini':
        _twins(canvas, c, r, stroke);
      case 'cancer':
        _cancer(canvas, c, r, stroke);
      case 'leo':
        _leo(canvas, c, r, stroke);
      case 'virgo':
        _m(canvas, c, r, stroke, sting: false);
      case 'libra':
        _libra(canvas, c, r, stroke);
      case 'scorpio':
        _m(canvas, c, r, stroke, sting: true);
      case 'sagittarius':
        _arrow(canvas, c, r, stroke);
      case 'capricorn':
        _capricorn(canvas, c, r, stroke);
      case 'aquarius':
        _waves(canvas, c, r, stroke);
      case 'pisces':
        _pisces(canvas, c, r, stroke);
      default:
        _aries(canvas, c, r, stroke);
    }
  }

  static void _aries(Canvas canvas, Offset c, double r, Paint p) {
    final left = Path()
      ..moveTo(c.dx - r * 0.08, c.dy + r * 0.14)
      ..quadraticBezierTo(c.dx - r * 0.46, c.dy - r * 0.34, c.dx - r * 0.16, c.dy - r * 0.54);
    final right = Path()
      ..moveTo(c.dx + r * 0.08, c.dy + r * 0.14)
      ..quadraticBezierTo(c.dx + r * 0.46, c.dy - r * 0.34, c.dx + r * 0.16, c.dy - r * 0.54);
    canvas.drawPath(left, p);
    canvas.drawPath(right, p);
    canvas.drawCircle(c + Offset(0, r * 0.1), r * 0.14, p);
  }

  static void _taurus(Canvas canvas, Offset c, double r, Paint p) {
    canvas.drawCircle(c + Offset(0, r * 0.1), r * 0.26, p);
    canvas.drawArc(Rect.fromCircle(center: c + Offset(-r * 0.22, -r * 0.1), radius: r * 0.2), math.pi * 0.15, math.pi * 0.9, false, p);
    canvas.drawArc(Rect.fromCircle(center: c + Offset(r * 0.22, -r * 0.1), radius: r * 0.2), math.pi * 0.95, math.pi * 0.9, false, p);
  }

  static void _twins(Canvas canvas, Offset c, double r, Paint p) {
    canvas.drawLine(c + Offset(-r * 0.18, -r * 0.42), c + Offset(-r * 0.18, r * 0.42), p);
    canvas.drawLine(c + Offset(r * 0.18, -r * 0.42), c + Offset(r * 0.18, r * 0.42), p);
    canvas.drawLine(c + Offset(-r * 0.18, -r * 0.34), c + Offset(r * 0.18, -r * 0.34), p);
    canvas.drawLine(c + Offset(-r * 0.18, r * 0.34), c + Offset(r * 0.18, r * 0.34), p);
  }

  static void _cancer(Canvas canvas, Offset c, double r, Paint p) {
    canvas.drawCircle(c + Offset(-r * 0.16, 0), r * 0.16, p);
    canvas.drawCircle(c + Offset(r * 0.16, 0), r * 0.16, p);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.42), math.pi * 0.85, math.pi * 0.55, false, p);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.42), math.pi * 1.85, math.pi * 0.55, false, p);
  }

  static void _leo(Canvas canvas, Offset c, double r, Paint p) {
    canvas.drawCircle(c + Offset(-r * 0.08, r * 0.06), r * 0.2, p);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.42), -math.pi * 0.2, math.pi * 1.4, false, p);
  }

  static void _m(Canvas canvas, Offset c, double r, Paint p, {required bool sting}) {
    final path = Path()
      ..moveTo(c.dx - r * 0.42, c.dy + r * 0.28)
      ..lineTo(c.dx - r * 0.42, c.dy - r * 0.28)
      ..lineTo(c.dx, c.dy + r * 0.08)
      ..lineTo(c.dx + r * 0.28, c.dy - r * 0.28)
      ..lineTo(c.dx + r * 0.28, c.dy + r * 0.28);
    if (sting) {
      path
        ..lineTo(c.dx + r * 0.46, c.dy + r * 0.08)
        ..lineTo(c.dx + r * 0.38, c.dy + r * 0.38);
    } else {
      path.quadraticBezierTo(c.dx + r * 0.52, c.dy + r * 0.12, c.dx + r * 0.36, c.dy - r * 0.08);
    }
    canvas.drawPath(path, p);
  }

  static void _libra(Canvas canvas, Offset c, double r, Paint p) {
    canvas.drawArc(Rect.fromCircle(center: c + Offset(0, -r * 0.12), radius: r * 0.28), math.pi, math.pi, false, p);
    canvas.drawLine(c + Offset(-r * 0.46, r * 0.12), c + Offset(r * 0.46, r * 0.12), p);
    canvas.drawLine(c + Offset(-r * 0.32, r * 0.28), c + Offset(r * 0.32, r * 0.28), p);
  }

  static void _arrow(Canvas canvas, Offset c, double r, Paint p) {
    canvas.drawLine(c + Offset(-r * 0.4, r * 0.32), c + Offset(r * 0.36, -r * 0.34), p);
    canvas.drawLine(c + Offset(r * 0.08, -r * 0.36), c + Offset(r * 0.36, -r * 0.34), p);
    canvas.drawLine(c + Offset(r * 0.36, -r * 0.08), c + Offset(r * 0.36, -r * 0.34), p);
    canvas.drawLine(c + Offset(-r * 0.08, r * 0.04), c + Offset(r * 0.12, r * 0.24), p);
  }

  static void _capricorn(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path()
      ..moveTo(c.dx - r * 0.38, c.dy + r * 0.3)
      ..lineTo(c.dx - r * 0.2, c.dy - r * 0.32)
      ..lineTo(c.dx + r * 0.08, c.dy + r * 0.08)
      ..quadraticBezierTo(c.dx + r * 0.42, c.dy + r * 0.28, c.dx + r * 0.22, c.dy - r * 0.08);
    canvas.drawPath(path, p);
  }

  static void _waves(Canvas canvas, Offset c, double r, Paint p) {
    for (final dy in [-0.12, 0.16]) {
      final path = Path()
        ..moveTo(c.dx - r * 0.42, c.dy + r * dy)
        ..quadraticBezierTo(c.dx - r * 0.18, c.dy + r * (dy - 0.16), c.dx, c.dy + r * dy)
        ..quadraticBezierTo(c.dx + r * 0.18, c.dy + r * (dy + 0.16), c.dx + r * 0.42, c.dy + r * dy);
      canvas.drawPath(path, p);
    }
  }

  static void _pisces(Canvas canvas, Offset c, double r, Paint p) {
    canvas.drawArc(Rect.fromCircle(center: c + Offset(-r * 0.18, 0), radius: r * 0.32), -math.pi * 0.7, math.pi * 1.4, false, p);
    canvas.drawArc(Rect.fromCircle(center: c + Offset(r * 0.18, 0), radius: r * 0.32), math.pi * 0.3, math.pi * 1.4, false, p);
    canvas.drawLine(c + Offset(-r * 0.08, 0), c + Offset(r * 0.08, 0), p);
  }
}
