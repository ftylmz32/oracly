/// OR-1120 — Single onboarding slide.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import '../../models/onboarding_page_data.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.data,
    required this.progress,
  });

  final OnboardingPageData data;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = data.gradientColors ??
        [
          AppColors.purpleGlow.withValues(alpha: 0.45),
          AppColors.goldGlow.withValues(alpha: 0.18),
        ];

    return Padding(
      padding: AppSpacing.screenHorizontal.copyWith(
        top: AppSpacing.xxl,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        children: [
          Expanded(
            child: Opacity(
              opacity: progress.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - progress) * 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: colors),
                        boxShadow: AppShadows.goldGlow,
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          width: AppBorderWidth.hairline,
                        ),
                      ),
                      child: SizedBox(
                        width: AppSpacing.xxl * 3,
                        height: AppSpacing.xxl * 3,
                        child: Center(
                          child: data.iconAsset != null
                              ? OraclyAssetImage(
                                  assetPath: data.iconAsset!,
                                  width: AppSpacing.xxl + AppSpacing.xl,
                                  height: AppSpacing.xxl + AppSpacing.xl,
                                  fit: BoxFit.contain,
                                  fallback: Icon(
                                    data.icon,
                                    size: 56,
                                    color: AppColors.goldLight,
                                  ),
                                )
                              : Icon(
                                  data.icon,
                                  size: 56,
                                  color: AppColors.goldLight,
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxl),
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displaySmall.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      data.subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
