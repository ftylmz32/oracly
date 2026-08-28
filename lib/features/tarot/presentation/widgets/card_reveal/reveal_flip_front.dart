/// Revealed face — artwork dominant; printed material; name lives outside.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../art/tarot_major_card_art.dart';
import '../../../motion/tarot_foil_glide.dart';
import '../../../theme/tarot_tokens.dart';
import '../deck/physical_card_thickness.dart';
import '../deck/tarot_printed_material.dart';
import 'card_reveal_spread.dart';

class RevealFlipFront extends StatelessWidget {
  const RevealFlipFront({
    super.key,
    required this.data,
    required this.width,
    required this.height,
    required this.goldOpacity,
    required this.artOpacity,
    this.lightBiasX = 0,
    this.lightBiasY = 0,
  });

  final RevealCardData data;
  final double width;
  final double height;
  final double goldOpacity;
  final double artOpacity;
  final double lightBiasX;
  final double lightBiasY;

  @override
  Widget build(BuildContext context) {
    final radius = TarotTokens.cardCornerRadius;
    final gold = goldOpacity.clamp(0.0, 1.0);
    final art = artOpacity.clamp(0.0, 1.0);

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: AppColors.purpleDark.withValues(alpha: 0.92 * gold),
          boxShadow: tarotContactShadow(elevation: 0.7 + gold * 0.25),
          border: Border.all(
            color: AppColors.gold.withValues(
              alpha: (0.48 + gold * 0.28).clamp(0.0, 1.0),
            ),
            width: 1.1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: art,
                child: Transform.rotate(
                  angle: data.isReversed ? pi : 0,
                  child: TarotMajorCardArt(
                    imageAsset: data.imageAsset,
                    preview: false,
                    showChrome: false,
                  ),
                ),
              ),
              PhysicalCardThickness(elevation: 0.55 + gold * 0.2),
              TarotPrintedMaterial(
                lightBiasX: lightBiasX,
                lightBiasY: lightBiasY,
                foil: 0.5 + gold * 0.25,
                matte: 0.48,
              ),
              TarotFoilGlide(
                progress: art,
                lightBiasX: lightBiasX,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
