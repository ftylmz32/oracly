/// Soft atmospheric glow — blur on capable GPUs, radial rest on HD+.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import 'oracly_quiet_motion.dart';

/// Circular wash that preserves chamber fog without perpetual GPU blur on KN8.
class OraclySoftGlow extends StatelessWidget {
  const OraclySoftGlow({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    this.sigma = 48,
    this.sigmaY,
  });

  final double width;
  final double height;
  final Color color;
  final double sigma;
  final double? sigmaY;

  @override
  Widget build(BuildContext context) {
    final soft = OraclyQuietMotion.constrained(context);
    final blob = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: soft
            ? RadialGradient(
                colors: [
                  color,
                  color.withValues(alpha: color.a * 0.45),
                  color.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.42, 1.0],
              )
            : null,
        color: soft ? null : color,
      ),
    );
    if (soft) return IgnorePointer(child: blob);
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigmaY ?? sigma,
        ),
        child: blob,
      ),
    );
  }
}
