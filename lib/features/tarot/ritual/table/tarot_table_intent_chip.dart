/// Single intention chip for [TarotTableIntentOverlay].
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/oracly_brand_signature.dart';
import '../../theme/tarot_tokens.dart';
import 'tarot_table_intent_catalogue.dart';

class TarotTableIntentChip extends StatelessWidget {
  const TarotTableIntentChip({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final TableIntentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: option.title,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: OraclyA11y.minTouchTarget,
          ),
          child: AnimatedContainer(
            duration: OraclySignatureMotion.press,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: selected
                  ? TarotTokens.tableChipSelected.withValues(alpha: 0.85)
                  : TarotTokens.tableChipPlate.withValues(alpha: 0.72),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: selected ? 0.7 : 0.28),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color:
                            AppColors.violetLuminous.withValues(alpha: 0.28),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(option.icon, size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                Text(
                  option.title,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
