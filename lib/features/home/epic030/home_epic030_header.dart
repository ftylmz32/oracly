/// EPIC-030 — Approved Home header: menu · ORACLY · premium capsule.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_typography.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'home_epic030_spec.dart';

class HomeEpic030Header extends StatelessWidget {
  const HomeEpic030Header({
    super.key,
    this.gemCount = '0',
    this.onMenuTap,
    this.onPremiumTap,
  });

  final String gemCount;
  final VoidCallback? onMenuTap;
  final VoidCallback? onPremiumTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeEpic030Spec.headerHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: HomeEpic030Spec.headerSideSlot,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _CircleAction(
                icon: Icons.menu_rounded,
                label: OraclyL10n.t('nav.menu'),
                onTap: onMenuTap ??
                    () => OraclyNavigationService.openSettings(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'ORACLY',
              textAlign: TextAlign.center,
              style: AppTypography.headingM.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                height: 1,
                color: AppColors.goldLight.withValues(alpha: 0.90),
              ),
            ),
          ),
          SizedBox(
            width: HomeEpic030Spec.headerSideSlot,
            child: Align(
              alignment: Alignment.centerRight,
              child: _PremiumCapsule(
                count: gemCount,
                onTap: onPremiumTap ??
                    () => OraclyNavigationService.openPremium(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: OraclyPressable(
        onTap: onTap,
        borderRadius: AppRadius.round,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceElevated.withValues(alpha: 0.72),
                AppColors.surface.withValues(alpha: 0.55),
              ],
            ),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.22),
              width: AppBorderWidth.hairline,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: SizedBox(
            width: HomeEpic030Spec.headerAction,
            height: HomeEpic030Spec.headerAction,
            child: Icon(
              icon,
              size: HomeEpic030Spec.headerIcon,
              color: AppColors.goldLight.withValues(alpha: 0.88),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumCapsule extends StatelessWidget {
  const _PremiumCapsule({
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
