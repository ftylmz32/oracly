/// Home Tarot tile — ORACLY deck silhouette, celestial backs, gold ornament.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/oracly_brand_signature.dart';

class HomeTarotModuleArt extends StatelessWidget {
  const HomeTarotModuleArt({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: HomeTarotModulePainter(),
      child: SizedBox.expand(),
    );
  }
}

class HomeTarotModulePainter extends CustomPainter {
  const HomeTarotModulePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0E32),
            OraclySignaturePalette.royalPurple,
            OraclySignaturePalette.obsidian,
          ],
        ).createShader(rect),
    );
    _stack(canvas, size);
    _witness(canvas, Offset(size.width * 0.52, size.height * 0.36), size);
  }

  void _stack(Canvas canvas, Size size) {
    final w = size.width * 0.36;
    final h = w * 1.55;
    final origin = Offset(size.width * 0.32, size.height * 0.16);
    _card(canvas, origin + const Offset(-12, 8), w, h, -0.18);
    _card(canvas, origin + const Offset(16, 5), w, h, 0.16);
    _card(canvas, origin, w, h, 0);
  }

  void _card(Canvas canvas, Offset origin, double w, double h, double angle) {
    canvas.save();
    canvas.translate(origin.dx + w / 2, origin.dy + h / 2);
    canvas.rotate(angle);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Radius.circular(w * 0.11),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFF140A24).withValues(alpha: 0.96),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..color = OraclySignaturePalette.goldEngrave(0.78),
    );
    canvas.drawRRect(
      rrect.deflate(3.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = OraclySignaturePalette.goldHairline(0.35),
    );
    // ORACLY celestial back — oval plate + witness cross.
    final gold = OraclySignaturePalette.goldEngrave(0.62);
    canvas.drawRRect(
      rrect.deflate(w * 0.12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.55
        ..color = gold.withValues(alpha: 0.35),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.42, height: h * 0.36),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75
        ..color = gold,
    );
    canvas.drawCircle(Offset.zero, w * 0.09, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = gold);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      canvas.drawLine(
        Offset(math.cos(a) * w * 0.05, math.sin(a) * w * 0.05),
        Offset(math.cos(a) * w * 0.18, math.sin(a) * w * 0.18),
        Paint()
          ..strokeWidth = 0.75
          ..color = gold,
      );
    }
    canvas.restore();
  }

  void _witness(Canvas canvas, Offset c, Size size) {
    final s = size.shortestSide * 0.2;
    final gold = const Color(0xFFF5D98A);
    canvas.drawCircle(
      c,
      s * 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = gold,
    );
    final star = Path()
      ..moveTo(c.dx, c.dy - s * 0.32)
      ..lineTo(c.dx + s * 0.05, c.dy - s * 0.05)
      ..lineTo(c.dx + s * 0.32, c.dy)
      ..lineTo(c.dx + s * 0.05, c.dy + s * 0.05)
      ..lineTo(c.dx, c.dy + s * 0.32)
      ..lineTo(c.dx - s * 0.05, c.dy + s * 0.05)
      ..lineTo(c.dx - s * 0.32, c.dy)
      ..lineTo(c.dx - s * 0.05, c.dy - s * 0.05)
      ..close();
    canvas.drawPath(star, Paint()..color = gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
