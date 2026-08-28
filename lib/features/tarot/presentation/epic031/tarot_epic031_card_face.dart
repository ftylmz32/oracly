/// EPIC-031 — Navy/gold tarot card face matching project artwork language.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class TarotEpic031CardFace extends CustomPainter {
  const TarotEpic031CardFace({this.emphasized = false});

  final bool emphasized;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.shortestSide * 0.12);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF14102A),
            AppColors.backgroundSecondary,
            const Color(0xFF070510),
          ],
        ).createShader(rect),
    );

    final glowR = size.shortestSide * 0.42;
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.46),
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.purpleGlow.withValues(alpha: emphasized ? 0.36 : 0.22),
            AppColors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width / 2, size.height * 0.46),
            radius: glowR,
          ),
        ),
    );

    _borders(canvas, size, rrect);
    _cornerStars(canvas, size);
    _sunMoon(canvas, size);
    _stars(canvas, size);
  }

  void _borders(Canvas canvas, Size size, RRect outer) {
    canvas.drawRRect(
      outer.deflate(1.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.gold.withValues(alpha: 0.88),
    );
    canvas.drawRRect(
      outer.deflate(size.shortestSide * 0.08),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AppColors.goldLight.withValues(alpha: 0.42),
    );
  }

  void _cornerStars(Canvas canvas, Size size) {
    final inset = size.shortestSide * 0.14;
    final gold = AppColors.gold.withValues(alpha: 0.70);
    final spark = AppColors.goldLight.withValues(alpha: 0.90);
    for (final o in [
      Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ]) {
      canvas.drawCircle(
        o,
        3.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = gold,
      );
      _spark(canvas, o, 2.4, spark);
    }
  }

  void _sunMoon(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.46);
    final r = size.shortestSide * 0.18;
    canvas.drawCircle(
      c,
      r * 1.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.goldLight.withValues(alpha: 0.22),
            AppColors.purple.withValues(alpha: 0.10),
            AppColors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.55)),
    );
    canvas.drawCircle(c, r, Paint()..color = AppColors.goldLight.withValues(alpha: 0.92));
    canvas.drawCircle(
      c + Offset(r * 0.38, -r * 0.06),
      r * 0.86,
      Paint()..color = const Color(0xFF120C22),
    );
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      canvas.drawLine(
        c + Offset(math.cos(a) * r * 1.18, math.sin(a) * r * 1.18),
        c + Offset(math.cos(a) * r * 1.42, math.sin(a) * r * 1.42),
        Paint()
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round
          ..color = AppColors.gold.withValues(alpha: 0.55),
      );
    }
  }

  void _stars(Canvas canvas, Size size) {
    final color = AppColors.goldLight.withValues(alpha: 0.78);
    _spark(canvas, Offset(size.width * 0.50, size.height * 0.18), 2.4, color);
    _spark(canvas, Offset(size.width * 0.50, size.height * 0.78), 2.2, color);
    _spark(canvas, Offset(size.width * 0.28, size.height * 0.34), 1.4, color);
    _spark(canvas, Offset(size.width * 0.72, size.height * 0.64), 1.3, color);
  }

  void _spark(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(0, -r), c + Offset(0, r), paint);
    canvas.drawLine(c + Offset(-r, 0), c + Offset(r, 0), paint);
  }

  @override
  bool shouldRepaint(covariant TarotEpic031CardFace oldDelegate) =>
      oldDelegate.emphasized != emphasized;
}
