/// Hero atmosphere — light moves; portrait stays still.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';

class HomeReferenceHeroAtmosphere extends StatelessWidget {
  const HomeReferenceHeroAtmosphere({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(t * math.pi * 2);
    final violet = 0.10 + wave.abs() * 0.045;
    final cx = 0.55 + wave * 0.04;
    final cy = -0.20 + math.cos(t * math.pi * 2) * 0.03;
    final gold = 0.035 + wave.abs() * 0.02;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(cx, cy),
              radius: 1.15,
              colors: [
                OraclyChrome.violet.withValues(alpha: violet),
                OraclyChrome.midnight.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        // Slow cosmic shimmer — never over the face plane.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.72 + wave * 0.05, -0.35),
              radius: 0.55,
              colors: [
                OraclyChrome.goldLight.withValues(alpha: gold),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                OraclyChrome.midnight.withValues(alpha: 0.22),
                Colors.transparent,
                OraclyChrome.midnight.withValues(alpha: 0.38),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.05,
              colors: [
                Colors.transparent,
                OraclyChrome.midnight.withValues(alpha: 0.35),
              ],
              stops: const [0.62, 1.0],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xE605030C),
                Color(0x990A0618),
                Color(0x4D140A28),
                Color(0x14080514),
                Color(0x00000000),
              ],
              stops: [0.0, 0.22, 0.42, 0.62, 0.82],
            ),
          ),
        ),
      ],
    );
  }
}
