/// OR-1030 / OR-426 — Artifact tarot card back for shuffle and selection.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../widgets/tarot_card_back_painter.dart';
import '../../../theme/tarot_tokens.dart';

/// Ancient face-down card — presence through material, not animation.
class ShuffleCardFace extends StatelessWidget {
  const ShuffleCardFace({
    super.key,
    this.width = 72,
    this.height = 118,
    this.elevation = 0.5,
    this.lightBiasX = 0,
    this.lightBiasY = 0,
    this.touchDepth = 0,
  });

  final double width;
  final double height;
  final double elevation;

  /// Ambient room-light shift as the card drifts (-0.2 … 0.2).
  final double lightBiasX;
  final double lightBiasY;

  /// Finger contact depth — gold edges catch slightly more light.
  final double touchDepth;

  @override
  Widget build(BuildContext context) {
    final edge = 1.0 + elevation * 1.2;
    final lift = elevation.clamp(0.0, 1.0);
    final touch = touchDepth.clamp(0.0, 1.0);
    final contactY = 2.5 + lift * 4.5 - touch * 0.8;
    final separationBlur = 6.0 + lift * 10.0 - touch * 3.0;
    final radius = TarotTokens.cardCornerRadius;
    final innerRadius = radius - 1;
    final clipRadius = radius - 1.5;

    return SizedBox(
      width: width,
      height: height + contactY * 0.35,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: contactY * 0.85,
            child: Transform.scale(
              scaleX: 0.78 + lift * 0.06,
              child: Container(
                width: width * 0.72,
                height: 5 + lift * 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.38 + lift * 0.12),
                      blurRadius: 4 + lift * 3,
                      spreadRadius: -1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.42 + lift * 0.18),
                  blurRadius: separationBlur,
                  offset: Offset(0, 2.5 + lift * 4),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: OraclySignaturePalette.obsidian.withValues(alpha: 0.55),
                  blurRadius: 2,
                  offset: Offset(0, 1 + lift),
                  spreadRadius: -3,
                ),
                if (lift > 0.55)
                  BoxShadow(
                    color: OraclySignaturePalette.goldEngrave(0.06 + lift * 0.04),
                    blurRadius: 14,
                    spreadRadius: -4,
                  ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OraclySignaturePalette.champagneDeep.withValues(
                    alpha: 0.22 + lift * 0.08,
                  ),
                  OraclySignaturePalette.champagneShadow.withValues(alpha: 0.48),
                  OraclySignaturePalette.champagneShadow.withValues(alpha: 0.62),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(0.9),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(innerRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      OraclySignaturePalette.crystalVeil,
                      OraclySignaturePalette.deepViolet,
                      OraclySignaturePalette.obsidian,
                    ],
                    stops: const [0.0, 0.52, 1.0],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(clipRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: TarotCardBackPainter(
                          lightBiasX: lightBiasX,
                          lightBiasY: lightBiasY,
                        ),
                      ),
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
                                  alpha: 0.22 +
                                      lightBiasX.abs() * 0.08 +
                                      touch * 0.14,
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
