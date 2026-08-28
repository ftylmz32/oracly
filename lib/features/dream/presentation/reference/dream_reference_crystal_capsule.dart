/// Crystal gem capsule for Dream Analysis header.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

class DreamReferenceCrystalCapsule extends StatelessWidget {
  const DreamReferenceCrystalCapsule({
    super.key,
    required this.count,
    this.onTap,
  });

  final String count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      borderRadius: AppRadius.round,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.round,
          color: AppColors.surface.withValues(alpha: 0.88),
          border: Border.all(
            color: AppColors.purpleLight.withValues(alpha: 0.38),
            width: AppBorderWidth.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purpleGlow.withValues(alpha: 0.22),
              blurRadius: AppShadowMetrics.iconBlur,
            ),
            ...AppShadows.soft,
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sm + AppSpacing.xs,
            AppSpacing.xs + 2,
            AppSpacing.xs,
            AppSpacing.xs + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.diamond_rounded,
                size: AppSpacing.md,
                color: AppColors.purpleLight.withValues(alpha: 0.92),
              ),
              SizedBox(width: AppSpacing.xs + 2),
              Text(
                count,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
