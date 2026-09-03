/// Project-owned gold line-art icons for Luna shortcuts and prompts.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

enum CompanionLineIconKind {
  tarot,
  coffee,
  dream,
  astrology,
  soulmate,
  crystal,
  heart,
  cards,
}

class CompanionGoldLineIcon extends StatelessWidget {
  const CompanionGoldLineIcon({
    super.key,
    required this.kind,
    this.size = 22,
  });

  final CompanionLineIconKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GoldLinePainter(kind),
    );
  }
}

class _GoldLinePainter extends CustomPainter {
  _GoldLinePainter(this.kind);

  final CompanionLineIconKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          OraclyChrome.goldLight.withValues(alpha: 0.98),
          OraclyChrome.gold.withValues(alpha: 0.88),
        ],
      ).createShader(Offset.zero & size);

    final s = size.width;
    switch (kind) {
      case CompanionLineIconKind.tarot:
      case CompanionLineIconKind.cards:
        _cards(canvas, s, stroke);
      case CompanionLineIconKind.coffee:
        _coffee(canvas, s, stroke);
      case CompanionLineIconKind.dream:
        _dream(canvas, s, stroke);
      case CompanionLineIconKind.astrology:
        _wheel(canvas, s, stroke);
      case CompanionLineIconKind.soulmate:
      case CompanionLineIconKind.heart:
        _heart(canvas, s, stroke);
      case CompanionLineIconKind.crystal:
        _crystal(canvas, s, stroke);
    }
  }



  void _cards(Canvas canvas, double s, Paint p) {
    final a = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.12, s * 0.28, s * 0.34, s * 0.52),
      Radius.circular(s * 0.05),
    );
    final b = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.33, s * 0.18, s * 0.34, s * 0.52),
      Radius.circular(s * 0.05),
    );
    final c = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.54, s * 0.26, s * 0.34, s * 0.52),
      Radius.circular(s * 0.05),
    );
    canvas.drawRRect(a, p);
    canvas.drawRRect(c, p);
    canvas.drawRRect(b, p);
    canvas.drawLine(Offset(s * 0.42, s * 0.36), Offset(s * 0.58, s * 0.36), p);
    canvas.drawLine(Offset(s * 0.50, s * 0.30), Offset(s * 0.50, s * 0.46), p);
  }

  void _coffee(Canvas canvas, double s, Paint p) {
    final cup = Path()
      ..moveTo(s * 0.24, s * 0.38)
      ..lineTo(s * 0.30, s * 0.70)
      ..quadraticBezierTo(s * 0.50, s * 0.78, s * 0.70, s * 0.70)
      ..lineTo(s * 0.76, s * 0.38)
      ..close();
    canvas.drawPath(cup, p);
    canvas.drawArc(
      Rect.fromLTWH(s * 0.72, s * 0.44, s * 0.16, s * 0.20),
      -1.2,
      2.4,
      false,
      p,
    );
    canvas.drawArc(
      Rect.fromLTWH(s * 0.28, s * 0.74, s * 0.44, s * 0.12),
      0.15,
      2.85,
      false,
      p,
    );
    canvas.drawArc(
      Rect.fromLTWH(s * 0.36, s * 0.18, s * 0.12, s * 0.18),
      3.4,
      2.2,
      false,
      p,
    );
    canvas.drawArc(
      Rect.fromLTWH(s * 0.52, s * 0.16, s * 0.12, s * 0.18),
      3.4,
      2.2,
      false,
      p,
    );
  }

  void _dream(Canvas canvas, double s, Paint p) {
    canvas.drawArc(
      Rect.fromLTWH(s * 0.22, s * 0.28, s * 0.42, s * 0.42),
      -0.4,
      4.4,
      false,
      p,
    );
    canvas.drawCircle(Offset(s * 0.68, s * 0.30), s * 0.045, p);
    canvas.drawCircle(Offset(s * 0.78, s * 0.42), s * 0.03, p);
    canvas.drawCircle(Offset(s * 0.70, s * 0.52), s * 0.025, p);
    final cloud = Path()
      ..moveTo(s * 0.22, s * 0.70)
      ..quadraticBezierTo(s * 0.18, s * 0.58, s * 0.32, s * 0.56)
      ..quadraticBezierTo(s * 0.40, s * 0.46, s * 0.52, s * 0.54)
      ..quadraticBezierTo(s * 0.68, s * 0.50, s * 0.70, s * 0.62)
      ..quadraticBezierTo(s * 0.82, s * 0.64, s * 0.78, s * 0.74)
      ..lineTo(s * 0.24, s * 0.74)
      ..close();
    canvas.drawPath(cloud, p);
  }

  void _wheel(Canvas canvas, double s, Paint p) {
    final c = Offset(s * 0.5, s * 0.5);
    canvas.drawCircle(c, s * 0.34, p);
    canvas.drawCircle(c, s * 0.14, p);
    for (var i = 0; i < 6; i++) {
      final a = i * 3.14159265 / 3;
      canvas.drawLine(
        Offset(c.dx + s * 0.14 * math.cos(a), c.dy + s * 0.14 * math.sin(a)),
        Offset(c.dx + s * 0.34 * math.cos(a), c.dy + s * 0.34 * math.sin(a)),
        p,
      );
    }
  }

  void _heart(Canvas canvas, double s, Paint p) {
    final path = Path()
      ..moveTo(s * 0.50, s * 0.72)
      ..cubicTo(s * 0.18, s * 0.52, s * 0.18, s * 0.28, s * 0.36, s * 0.24)
      ..cubicTo(s * 0.46, s * 0.22, s * 0.50, s * 0.32, s * 0.50, s * 0.36)
      ..cubicTo(s * 0.50, s * 0.32, s * 0.54, s * 0.22, s * 0.64, s * 0.24)
      ..cubicTo(s * 0.82, s * 0.28, s * 0.82, s * 0.52, s * 0.50, s * 0.72)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawLine(Offset(s * 0.22, s * 0.58), Offset(s * 0.78, s * 0.30), p);
    canvas.drawCircle(Offset(s * 0.72, s * 0.26), s * 0.03, p);
  }

  void _crystal(Canvas canvas, double s, Paint p) {
    final path = Path()
      ..moveTo(s * 0.50, s * 0.14)
      ..lineTo(s * 0.72, s * 0.38)
      ..lineTo(s * 0.62, s * 0.82)
      ..lineTo(s * 0.38, s * 0.82)
      ..lineTo(s * 0.28, s * 0.38)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawLine(Offset(s * 0.50, s * 0.14), Offset(s * 0.50, s * 0.82), p);
    canvas.drawLine(Offset(s * 0.28, s * 0.38), Offset(s * 0.72, s * 0.38), p);
  }


  @override
  bool shouldRepaint(covariant _GoldLinePainter oldDelegate) =>
      oldDelegate.kind != kind;
}
