/// OR-1090 — Subscription plan selector cards.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../models/premium_models.dart';

class PremiumPlanSelector extends StatelessWidget {
  const PremiumPlanSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.entrance,
  });

  final PremiumPlanType selected;
  final ValueChanged<PremiumPlanType> onSelected;
  final double entrance;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance) * 18;
    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Üyelik Planı',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              ...PremiumPlanType.values.map(
                (plan) => Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PlanCard(
                    plan: plan,
                    selected: plan == selected,
                    onTap: () => onSelected(plan),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PremiumPlanType plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDuration.normal,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.goldGlow.withValues(alpha: 0.35),
                    blurRadius: 18,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.lg,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: AppDuration.normal,
              padding: AppSpacing.card,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceElevated.withValues(alpha: 0.92),
                    AppColors.surface.withValues(alpha: 0.84),
                  ],
                ),
                borderRadius: AppRadius.lg,
                border: Border.all(
                  color: selected
                      ? AppColors.gold.withValues(alpha: 0.72)
                      : AppColors.gold.withValues(alpha: 0.22),
                  width: selected ? AppBorderWidth.thin : AppBorderWidth.hairline,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: AppDuration.fast,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.gold
                            : AppColors.gold.withValues(alpha: 0.35),
                        width: AppBorderWidth.thin,
                      ),
                      color: selected
                          ? AppColors.gold.withValues(alpha: 0.25)
                          : AppColors.transparent,
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: AppColors.goldLight,
                          )
                        : null,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.label,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          plan.subtitle,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    plan.price,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
