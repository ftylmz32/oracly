/// Spread choice tile for [TarotTableSpreadOverlay].
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/oracly_brand_signature.dart';
import '../../theme/tarot_tokens.dart';

class TarotTableSpreadTile extends StatelessWidget {
  const TarotTableSpreadTile({
    super.key,
    required this.title,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: OraclyA11y.minTouchTarget,
          ),
          child: AnimatedContainer(
            duration: OraclySignatureMotion.press,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: TarotTokens.tableChipPlate.withValues(alpha: 0.8),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: selected ? 0.75 : 0.25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < count; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      Container(
                        width: count > 3 ? 7 : 9,
                        height: count > 3 ? 11 : 14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.55),
                          ),
                          color: TarotTokens.tableMiniCardFill,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.gold,
                    letterSpacing: 0.4,
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
