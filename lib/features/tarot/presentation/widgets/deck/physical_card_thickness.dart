/// Paper-edge thickness for a face-down tarot card.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../theme/tarot_tokens.dart';

/// Right and bottom paper edges — the deck feels like a physical object.
class PhysicalCardThickness extends StatelessWidget {
  const PhysicalCardThickness({
    super.key,
    this.elevation = 0.5,
  });

  final double elevation;

  @override
  Widget build(BuildContext context) {
    final lift = elevation.clamp(0.0, 1.0);
    final radius = TarotTokens.cardCornerRadius;
    final edge = Color.lerp(
      OraclySignaturePalette.champagneShadow,
      OraclySignaturePalette.champagneDeep,
      0.35 + lift * 0.25,
    )!;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(radius),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    edge.withValues(alpha: 0.55 + lift * 0.2),
                    OraclySignaturePalette.champagne.withValues(
                      alpha: 0.18 + lift * 0.1,
                    ),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
              child: const SizedBox(width: 3.2, height: double.infinity),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(radius),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    edge.withValues(alpha: 0.62 + lift * 0.18),
                  ],
                ),
              ),
              child: const SizedBox(width: double.infinity, height: 2.6),
            ),
          ),
        ],
      ),
    );
  }
}
