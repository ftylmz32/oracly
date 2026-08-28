/// Compact labeled picker row for birth-chart onboarding.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class BirthChartFieldButton extends StatelessWidget {
  const BirthChartFieldButton({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return OraclyGlassCard(
      onTap: onTap,
      borderRadius: OraclyChrome.cardRadius,
      padding: OraclyChrome.cardPadding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: muted
                        ? AppColors.textHint
                        : OraclyChrome.goldLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: OraclyChrome.gold.withValues(alpha: 0.65),
          ),
        ],
      ),
    );
  }
}
