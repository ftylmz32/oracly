/// Subtle chamber light for the reveal beats — warm focus, never a flash.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_soft_glow.dart';

class RevealAtmosphericLight extends StatelessWidget {
  const RevealAtmosphericLight({
    super.key,
    required this.intensity,
    this.focus = 0,
  });

  final double intensity;
  final double focus;

  @override
  Widget build(BuildContext context) {
    final a = intensity.clamp(0.0, 1.0);
    if (a < 0.02) return const SizedBox.shrink();
    final tighten = focus.clamp(0.0, 1.0);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment(0, -0.22 - tighten * 0.04),
            child: OraclySoftGlow(
              width: 220 - tighten * 36,
              height: 260 - tighten * 28,
              sigma: 48,
              sigmaY: 42,
              color: const Color(0xFFE8C872).withValues(alpha: 0.11 * a),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.18),
                radius: 1.05 - tighten * 0.10,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.10 * a + tighten * 0.06),
                ],
                stops: const [0.38, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
