/// OR-1090 — Premium membership CTA button.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/copy/premium_copy.dart';
import '../../../../shared/widgets/oracly_button.dart';

class PremiumMembershipCta extends StatelessWidget {
  const PremiumMembershipCta({
    super.key,
    required this.entrance,
    required this.onActivate,
    this.isPremium = false,
  });

  final double entrance;
  final VoidCallback onActivate;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance) * 24;
    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lg,
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldGlow.withValues(alpha: 0.38),
                  blurRadius: 22,
                ),
              ],
            ),
            child: isPremium
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.purple.withValues(alpha: 0.6),
                          AppColors.purpleDark,
                        ],
                      ),
                      borderRadius: AppRadius.lg,
                    ),
                    child: SizedBox(
                      height: AppSpacing.xxl + AppSpacing.sm,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: AppColors.goldLight,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            PremiumCopy.ctaActive,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : OraclyButton(
                    text: PremiumCopy.ctaJoin,
                    icon: Icons.workspace_premium_rounded,
                    onPressed: onActivate,
                    isExpanded: true,
                    size: OraclyButtonSize.large,
                  ),
          ),
        ),
      ),
    );
  }
}
