/// One settled geometry slot tile (label + card / empty plate).
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../art/tarot_card_face_density.dart';
import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../../theme/tarot_tokens.dart';
import 'ritual_card_shell.dart';

class RitualSpreadSlotTile extends StatelessWidget {
  const RitualSpreadSlotTile({
    super.key,
    required this.label,
    required this.cardSize,
    this.card,
    this.settledRotationRad = 0,
  });

  final String label;
  final Size cardSize;
  final RevealCardData? card;
  final double settledRotationRad;

  @override
  Widget build(BuildContext context) {
    final radius = RitualCardMetrics.compactRadius(cardSize.width);
    Widget body = card != null
        ? RitualCardFace(
            label: card!.displayName,
            image: card!.imageAsset,
            reversed: card!.isReversed,
            width: cardSize.width,
            height: cardSize.height,
            density: TarotCardFaceDensity.compact,
          )
        : Container(
            width: cardSize.width,
            height: cardSize.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.22),
              ),
              color: TarotTokens.tableReadingPlate.withValues(alpha: 0.55),
            ),
          );
    if (settledRotationRad != 0) {
      body = Transform.rotate(angle: settledRotationRad, child: body);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.gold.withValues(alpha: 0.72),
            letterSpacing: 0.6,
            fontSize: 8.5,
          ),
        ),
        const SizedBox(height: 4),
        body,
      ],
    );
  }
}
