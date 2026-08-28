/// Quiet hero atmosphere — soft light drift, restrained star breath.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/oracly_quiet_motion.dart';

class DailyRitualHeroAtmosphere extends StatefulWidget {
  const DailyRitualHeroAtmosphere({super.key});

  @override
  State<DailyRitualHeroAtmosphere> createState() =>
      _DailyRitualHeroAtmosphereState();
}

class _DailyRitualHeroAtmosphereState extends State<DailyRitualHeroAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 11000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, reverse: true, rest: 0.42);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lean = OraclyQuietMotion.constrained(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, _) {
            return CustomPaint(
              painter: _HeroAtmospherePainter(
                t: _breath.value,
                lean: lean,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _HeroAtmospherePainter extends CustomPainter {
  _HeroAtmospherePainter({required this.t, required this.lean});

  final double t;
  final bool lean;

  @override
  void paint(Canvas canvas, Size size) {
    final drift = (t - 0.5) * (lean ? 4.0 : 8.0);

    // Soft cloud veil — atmospheric light movement.
    final cloud = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-0.25 + t * 0.10, -0.45),
        end: Alignment(1.05, 0.55 + t * 0.04),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.022 + t * 0.014),
          AppColors.gold.withValues(alpha: 0.012 + t * 0.010),
          Colors.transparent,
        ],
        stops: const [0.12, 0.42, 0.62, 0.94],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, cloud);

    final stars = lean ? 10 : 16;
    final rnd = math.Random(17);
    for (var i = 0; i < stars; i++) {
      final x =
          rnd.nextDouble() * size.width + drift * (i.isEven ? 0.12 : -0.08);
      final y = rnd.nextDouble() * size.height * 0.52;
      final twinkle =
          0.05 + 0.10 * ((math.sin((t + i * 0.19) * math.pi * 2) + 1) / 2);
      canvas.drawCircle(
        Offset(x, y),
        rnd.nextDouble() * 0.95 + 0.3,
        Paint()..color = Colors.white.withValues(alpha: twinkle),
      );
    }

    // Gold moon breath — slow radial drift.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0.52 + t * 0.04, -0.20 + t * 0.03),
          radius: 0.88 + t * 0.06,
          colors: [
            OraclyChrome.gold.withValues(alpha: 0.040 + t * 0.032),
            AppColors.primaryPurple.withValues(alpha: 0.018 + t * 0.012),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _HeroAtmospherePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.lean != lean;
}
