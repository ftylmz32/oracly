import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class TarotOracleHeader extends StatelessWidget {
  const TarotOracleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Oracly Oracle',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.gold.withValues(alpha: .72),
            letterSpacing: 2.2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 40,
          height: 1,
          color: AppColors.gold.withValues(alpha: .22),
        ),
      ],
    );
  }
}
