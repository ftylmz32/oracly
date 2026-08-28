import 'package:flutter/material.dart';

import '../../../core/design_system/app_gradients.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../copy/tarot_l10n.dart';
import '../models/tarot_card.dart';
import 'tarot_result_card_art.dart';

class TarotResultCardCompact extends StatelessWidget {
  const TarotResultCardCompact({
    super.key,
    required this.card,
    this.positionLabel,
  });

  final TarotCard card;
  final String? positionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        gradient: AppGradients.glass,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          TarotCardArt(image: card.image, compact: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (positionLabel != null)
                  Text(
                    positionLabel!.toUpperCase(),
                    style: AppTextStyles.label.copyWith(
                      fontSize: 9,
                      color: AppColors.gold.withValues(alpha: 0.65),
                    ),
                  ),
                Text(
                  TarotL10n.cardNameOf(card),
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.goldLight,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
