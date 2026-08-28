/// Artifact tarot card back — thickness, shadow, soft edge light.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../art/tarot_card_back_art.dart';
import '../../../theme/tarot_tokens.dart';
import '../deck/physical_card_thickness.dart';
import '../deck/tarot_printed_material.dart';
import 'shuffle_card_sheen.dart';

/// Face-down card as a physical object — presence through material.
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
  final double lightBiasX;
  final double lightBiasY;
  final double touchDepth;

  @override
  Widget build(BuildContext context) {
    final edge = 1.0 + elevation * 1.2;
    final lift = elevation.clamp(0.0, 1.0);
    final touch = touchDepth.clamp(0.0, 1.0);
    final contactY = 2.2 + lift * 4.2 - touch * 0.6;
    final radius = TarotTokens.cardCornerRadius;

    return SizedBox(
      width: width,
      height: height + contactY * 0.35,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: contactY * 0.9,
            child: Transform.scale(
              scaleX: 0.76 + lift * 0.05,
              child: Container(
                width: width * 0.7,
                height: 4.5 + lift * 1.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.48 + lift * 0.12),
                      blurRadius: 4.5 + lift * 3,
                      spreadRadius: -0.8,
                    ),
                    BoxShadow(
                      color: OraclySignaturePalette.champagne.withValues(
                        alpha: 0.05 + lift * 0.03,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
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
              boxShadow: tarotContactShadow(elevation: lift),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TarotCardBackArt(
                    lightBiasX: lightBiasX,
                    lightBiasY: lightBiasY,
                  ),
                  PhysicalCardThickness(elevation: lift),
                  ShuffleCardSheen(
                    edge: edge,
                    lift: lift,
                    touch: touch,
                    lightBiasX: lightBiasX,
                    lightBiasY: lightBiasY,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
