/// Subtle candle spill on the selection table — warm, never neon.
library;

import 'dart:math' show cos, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_quiet_motion.dart';

class CardSelectionCandle extends StatelessWidget {
  const CardSelectionCandle({
    super.key,
    required this.phase,
    this.gather = 0,
    this.breathMotion = 0.5,
  });

  final double phase;
  final double gather;
  final double breathMotion;

  @override
  Widget build(BuildContext context) {
    final drift = (1 - gather * 0.88).clamp(0.0, 1.0);
    final flame = Container(
      width: 170,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFE8C872).withValues(
              alpha: (0.11 + breathMotion * 0.04) * (1 - gather * 0.45),
            ),
            const Color(0xFFC48A3A).withValues(
              alpha: 0.05 * (1 - gather * 0.5),
            ),
            Colors.transparent,
          ],
        ),
      ),
    );
    return Transform.translate(
      offset: Offset(
        -48 + sin(phase) * 3 * drift,
        28 + cos(phase) * 2 * drift,
      ),
      child: OraclyQuietMotion.constrained(context)
          ? flame
          : ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 36),
              child: flame,
            ),
    );
  }
}
