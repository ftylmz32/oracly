/// Soft edge light riding on a physical card back.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_brand_signature.dart';

class ShuffleCardSheen extends StatelessWidget {
  const ShuffleCardSheen({
    super.key,
    required this.edge,
    required this.lift,
    required this.touch,
    required this.lightBiasX,
    required this.lightBiasY,
  });

  final double edge;
  final double lift;
  final double touch;
  final double lightBiasX;
  final double lightBiasY;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: edge,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  OraclySignaturePalette.champagne.withValues(
                    alpha: 0.22 + lightBiasX.abs() * 0.08 + touch * 0.14,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(
                  -0.75 + lightBiasX * 0.35,
                  -1 + lightBiasY * 0.25,
                ),
                end: Alignment(
                  0.45 + lightBiasX * 0.2,
                  0.55 + lightBiasY * 0.15,
                ),
                colors: [
                  Colors.white.withValues(
                    alpha: 0.06 + lift * 0.04 + touch * 0.05,
                  ),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.42],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: OraclySignatureReflection.facetSheen(
                intensity: 0.75 + lift * 0.25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
