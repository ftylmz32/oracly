/// TAROT V2 — already chosen cards, shown without extra instruction.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../copy/tarot_l10n.dart';
import '../../../domain/models/reading_session.dart';

class CardSelectionPicks extends StatelessWidget {
  const CardSelectionPicks({super.key, required this.cards});

  final List<TarotDrawnCard> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final card in cards)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.round,
                color: AppColors.surface.withValues(alpha: 0.5),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.38),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  '${card.localizedPosition} · ${card.localizedName} · '
                  '${TarotL10n.orientation(reversed: card.isReversed)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
