/// Reference dream hero — moon phases, sleeping figure, golden glow.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Large circular dream illustration (~45% viewport height).
class DreamReferenceHero extends StatefulWidget {
  const DreamReferenceHero({super.key});

  @override
  State<DreamReferenceHero> createState() => _DreamReferenceHeroState();
}

class _DreamReferenceHeroState extends State<DreamReferenceHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diameter = MediaQuery.sizeOf(context).height * 0.45;

    return SizedBox(
      height: diameter,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, _) {
          return CustomPaint(
            painter: _DreamReferenceHeroPainter(phase: _motion.value),
            size: Size(diameter, diameter),
          );
        },
      ),
    );
  }
}

class _DreamReferenceHeroPainter extends CustomPainter {
  const _DreamReferenceHeroPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);
    final radius = size.shortestSide * 0.42;
    final breath = 0.5 + math.sin(phase * math.pi * 2) * 0.5;

    canvas.drawCircle(
      center,
      radius * 1.22,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.goldGlow.withValues(alpha: 0.14 + breath * 0.06),
            AppColors.purpleGlow.withValues(alpha: 0.10),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.22)),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.purpleDark.withValues(alpha: 0.94),
            AppColors.secondaryPurple.withValues(alpha: 0.88),
            AppColors.backgroundSecondary.withValues(alpha: 0.96),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.gold.withValues(alpha: 0.28),
    );

    _paintMoonPhases(canvas, center, radius * 0.88, breath);
    _paintSleepingFigure(canvas, center, radius);
    _paintCentralMoon(canvas, center - Offset(0, radius * 0.22), radius * 0.22);
    _paintParticles(canvas, size, breath);
  }

  void _paintMoonPhases(Canvas canvas, Offset center, double orbitR, double breath) {
    const phases = 8;
    for (var i = 0; i < phases; i++) {
      final angle = (i / phases) * math.pi * 2 - math.pi / 2;
      final p = center + Offset(math.cos(angle) * orbitR, math.sin(angle) * orbitR);
      final lit = (math.cos(angle + phase * math.pi * 2) + 1) * 0.5;
      canvas.drawCircle(
        p,
        5.5,
        Paint()..color = AppColors.goldLight.withValues(alpha: 0.22 + lit * 0.55),
      );
      if (i.isEven) {
        canvas.drawArc(
          Rect.fromCircle(center: p, radius: 4.5),
          angle + math.pi * 0.5,
          math.pi * 0.85,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..color = AppColors.goldLight.withValues(alpha: 0.45 + lit * 0.25),
        );
      }
    }
  }

  void _paintCentralMoon(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(
      center,
      r * 1.15,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.goldLight.withValues(alpha: 0.24),
            AppColors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.15)),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()..color = AppColors.goldLight.withValues(alpha: 0.92),
    );
    canvas.drawCircle(
      center + Offset(r * 0.28, -r * 0.04),
      r * 0.88,
      Paint()..color = AppColors.purpleDark.withValues(alpha: 0.94),
    );
  }

  void _paintSleepingFigure(Canvas canvas, Offset center, double radius) {
    final baseY = center.dy + radius * 0.08;
    final headCenter = Offset(center.dx - radius * 0.08, baseY - radius * 0.08);
    canvas.drawCircle(
      headCenter,
      radius * 0.11,
      Paint()..color = AppColors.textPrimary.withValues(alpha: 0.78),
    );

    final body = Path()
      ..moveTo(headCenter.dx + radius * 0.08, headCenter.dy)
      ..quadraticBezierTo(
        center.dx + radius * 0.28,
        baseY + radius * 0.04,
        center.dx + radius * 0.34,
        baseY + radius * 0.16,
      )
      ..lineTo(center.dx - radius * 0.28, baseY + radius * 0.18)
      ..quadraticBezierTo(
        center.dx - radius * 0.12,
        baseY + radius * 0.06,
        headCenter.dx - radius * 0.02,
        headCenter.dy + radius * 0.04,
      )
      ..close();

    canvas.drawPath(
      body,
      Paint()..color = AppColors.textPrimary.withValues(alpha: 0.62),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, baseY + radius * 0.24),
          width: radius * 0.72,
          height: radius * 0.16,
        ),
        Radius.circular(radius * 0.08),
      ),
      Paint()..color = AppColors.surfaceElevated.withValues(alpha: 0.35),
    );
  }

  void _paintParticles(Canvas canvas, Size size, double breath) {
    for (var i = 0; i < 14; i++) {
      final seed = math.sin((i + 1) * 4.7) * 43758.5453;
      final u = seed - seed.floor();
      final v = math.sin((i + 3) * 2.1) * 12345.6789;
      final w = v - v.floor();
      final x = size.width * (0.12 + u * 0.76);
      final y = size.height * (0.08 + w * 0.84);
      final twinkle = 0.35 + math.sin(phase * math.pi * 2 + i) * 0.25;
      canvas.drawCircle(
        Offset(x, y),
        0.8 + u * 1.2,
        Paint()
          ..color = AppColors.goldLight.withValues(alpha: 0.14 * twinkle * breath),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DreamReferenceHeroPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

/// Small thumbnail for recent dream rows.
class DreamRecentThumbnail extends StatelessWidget {
  const DreamRecentThumbnail({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DreamReferenceHeroPainter(phase: 0.18),
          size: Size(size, size),
        ),
      ),
    );
  }
}
