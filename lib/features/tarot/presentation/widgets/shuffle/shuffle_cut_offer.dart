/// Optional cut invitation after the shuffle rests.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';
import '../../../copy/tarot_polish_copy.dart';

class ShuffleCutOffer extends StatelessWidget {
  const ShuffleCutOffer({
    super.key,
    required this.onCut,
    required this.onSkip,
  });

  final VoidCallback onCut;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: TarotPolishCopy.cutDeck,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OraclyPressable(
              haptic: false,
              softSound: false,
              onTap: onCut,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Center(
                  child: Text(
                    TarotPolishCopy.cutDeck,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            OraclyPressable(
              haptic: true,
              onTap: onSkip,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Center(
                  child: Text(
                    TarotPolishCopy.skipIntention,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
