/// Face art for the living reading card — decode sized by layout.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../art/tarot_major_card_art.dart';

class ReadingBreathingCardArt extends StatelessWidget {
  const ReadingBreathingCardArt({
    super.key,
    required this.imageAsset,
    required this.rarityColor,
  });

  final String imageAsset;
  final Color rarityColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        TarotMajorCardArt(
          imageAsset: imageAsset,
          showChrome: false,
          fallback: _ArtFallback(color: rarityColor),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x1FFFFFFF),
                Colors.transparent,
                Color(0x2E000000),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            heightFactor: 0.22,
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: OraclySignatureReflection.topSpecular(
                  intensity: 0.85,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtFallback extends StatelessWidget {
  const _ArtFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.45),
            AppColors.purpleDark,
            AppColors.primary,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: AppColors.goldLight,
          size: 36,
        ),
      ),
    );
  }
}
