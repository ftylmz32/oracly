/// On-table short reading — deepen / ask OR without leaving the table first.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';

class TarotTableReadingOverlay extends StatelessWidget {
  const TarotTableReadingOverlay({
    super.key,
    required this.card,
    required this.onDeepen,
    required this.onAskOr,
  });

  final RevealCardData card;
  final VoidCallback onDeepen;
  final VoidCallback onAskOr;

  @override
  Widget build(BuildContext context) {
    final short = card.card.summary.trim().isNotEmpty
        ? card.card.summary
        : (card.isReversed ? card.card.reversedMeaning : card.card.meaning);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        color: const Color(0xFF0A0714).withValues(alpha: 0.88),
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.28)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              card.displayName,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.gold,
              ),
            ),
            if ((card.positionLabel ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                card.positionLabel!,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              short,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.9),
                height: 1.55,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OraclyButton(
              text: 'Yorumu Derinleştir',
              isExpanded: true,
              onPressed: onDeepen,
            ),
            const SizedBox(height: 8),
            OraclyButton(
              text: "OR'a Sor",
              type: OraclyButtonType.secondary,
              isExpanded: true,
              onPressed: onAskOr,
            ),
          ],
        ),
      ),
    );
  }
}
