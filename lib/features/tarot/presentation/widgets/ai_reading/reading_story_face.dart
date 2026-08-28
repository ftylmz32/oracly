/// One revealed card: art dominant; name/orientation outside — never over art.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../copy/tarot_polish_copy.dart';
import 'ai_reading_content.dart';
import 'reading_breathing_card_art.dart';
import 'reading_sacred_rhythm.dart';

class ReadingStoryFaceSpec {
  const ReadingStoryFaceSpec({
    required this.imageAsset,
    required this.name,
    required this.position,
    required this.isReversed,
    required this.rarityColor,
  });

  final String imageAsset;
  final String name;
  final String position;
  final bool isReversed;
  final Color rarityColor;

  String get orientation =>
      isReversed ? TarotPolishCopy.reversed : TarotPolishCopy.upright;

  static List<ReadingStoryFaceSpec> of(AiReadingContent content) {
    if (content.drawnCards.isEmpty) {
      return [
        ReadingStoryFaceSpec(
          imageAsset: content.imageAsset,
          name: content.cardName,
          position: content.spreadLabel ?? TarotPolishCopy.cardField,
          isReversed: false,
          rarityColor: content.rarityColor,
        ),
      ];
    }
    return [
      for (final card in content.drawnCards)
        ReadingStoryFaceSpec(
          imageAsset: card.card.image,
          name: card.localizedName,
          position: card.localizedPosition,
          isReversed: card.isReversed,
          rarityColor: content.rarityColor,
        ),
    ];
  }
}

class ReadingStoryFace extends StatelessWidget {
  const ReadingStoryFace({
    super.key,
    required this.spec,
    this.hero = false,
  });

  final ReadingStoryFaceSpec spec;
  final bool hero;

  static double heightFor(double width) =>
      width * 1.55 + AppSpacing.xs * 2 + AppSpacing.sm + AppSpacing.xxl + AppSpacing.md;

  static double get stripHeight =>
      heightFor(ReadingSacredRhythm.companionCardWidth);

  @override
  Widget build(BuildContext context) {
    final width = hero
        ? ReadingSacredRhythm.heroCardWidth
        : ReadingSacredRhythm.companionCardWidth;
    return Semantics(
      label: '${spec.name}, ${spec.position}, ${spec.orientation}',
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              spec.position,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: ReadingTypography.sectionLabel(fontSize: 10),
            ),
            SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: width,
              height: width * 1.55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.md,
                  border: Border.all(
                    color: OraclySignaturePalette.goldEngrave(0.72),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.md,
                  child: Transform.rotate(
                    angle: spec.isReversed ? pi : 0,
                    child: ReadingBreathingCardArt(
                      imageAsset: spec.imageAsset,
                      rarityColor: spec.rarityColor,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              spec.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: ReadingTypography.bodySmall(color: AppColors.textPrimary),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              spec.orientation,
              textAlign: TextAlign.center,
              style: ReadingTypography.footnote(),
            ),
          ],
        ),
      ),
    );
  }
}
