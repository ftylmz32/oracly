/// OR-050 — Daily Energy Details screen header.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class DailyEnergyDetailsHeader extends StatelessWidget {
  const DailyEnergyDetailsHeader({
    super.key,
    required this.moonPhaseLabel,
    required this.dateLabel,
  });

  final String moonPhaseLabel;
  final String dateLabel;

  static const String _title = 'Günlük Enerji';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          _BackButton(onPressed: () => Navigator.of(context).maybePop()),
          Expanded(
            child: Column(
              children: [
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '$moonPhaseLabel · $dateLabel',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.xxl + AppSpacing.sm),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Geri',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface.withValues(alpha: 0.72),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.24),
                width: AppBorderWidth.hairline,
              ),
              boxShadow: AppShadows.soft,
            ),
            child: SizedBox(
              width: AppSpacing.xxl + AppSpacing.sm,
              height: AppSpacing.xxl + AppSpacing.sm,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: AppSpacing.md,
                color: AppColors.goldLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
