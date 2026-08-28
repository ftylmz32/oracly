/// Soft specular catch during the turn — candle on varnish, not a laser.
library;

import 'dart:math' show cos, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../theme/tarot_tokens.dart';

class RevealFlipSheen extends StatelessWidget {
  const RevealFlipSheen({
    super.key,
    required this.intensity,
    required this.flipRotation,
    required this.width,
    required this.height,
  });

  final double intensity;
  final double flipRotation;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final a = intensity.clamp(0.0, 1.0);
    if (a < 0.02) return const SizedBox.shrink();
    final x = cos(flipRotation) * 0.55;
    final y = -0.35 + sin(flipRotation) * 0.12;
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TarotTokens.cardCornerRadius),
            gradient: LinearGradient(
              begin: Alignment(x - 0.35, y - 0.4),
              end: Alignment(x + 0.55, y + 0.75),
              colors: [
                Colors.transparent,
                OraclySignaturePalette.champagne.withValues(alpha: 0.10 * a),
                Colors.white.withValues(alpha: 0.05 * a),
                Colors.transparent,
              ],
              stops: const [0.18, 0.46, 0.58, 0.82],
            ),
          ),
        ),
      ),
    );
  }
}
