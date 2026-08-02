import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
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
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        color: AppColors.surfaceDark.withValues(alpha: .55),
        border: Border.all(
          color: AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          TarotCardArt(
            image: card.image,
            compact: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (positionLabel != null)
                  Text(
                    positionLabel!,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textHint,
                      letterSpacing: 1.1,
                    ),
                  ),
                Text(
                  card.name,
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.gold.withValues(alpha: .88),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
