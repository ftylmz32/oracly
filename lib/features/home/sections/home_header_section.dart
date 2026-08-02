import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeHeaderSection extends StatelessWidget {
  const HomeHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORACLY',
                  style: AppTextStyles.logo.copyWith(
                    fontSize: 36,
                    letterSpacing: 3.2,
                    color: AppColors.gold.withValues(alpha: .9),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'AI Destiny Assistant',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withValues(
                      alpha: .68,
                    ),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: .08),
              border: Border.all(
                color: AppColors.glassBorder,
              ),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.gold.withValues(alpha: .75),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
