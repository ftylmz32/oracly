/// EPIC-032 — Approved Home header.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_glows.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'home_epic032_spec.dart';

class HomeEpic032Header extends StatelessWidget {
  const HomeEpic032Header({
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
      height: HomeEpic032Spec.headerHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: HomeEpic032Spec.headerSideSlot,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _MenuButton(
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
            width: HomeEpic032Spec.headerSideSlot,
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

class _MenuButton extends StatelessWidget {
  const _MenuButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: OraclyL10n.t('nav.menu'),
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
            boxShadow: AppGlows.small(strength: 0.6),
          ),
          child: SizedBox(
            width: HomeEpic032Spec.headerAction,
            height: HomeEpic032Spec.headerAction,
            child: Icon(
              Icons.menu_rounded,
              size: HomeEpic032Spec.headerIcon,
              color: AppColors.goldLight.withValues(alpha: 0.88),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumCapsule extends StatelessWidget {
  const _PremiumCapsule({required this.count, this.onTap});

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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceElevated.withValues(alpha: 0.72),
              AppColors.surface.withValues(alpha: 0.58),
            ],
          ),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.22),
            width: AppBorderWidth.hairline,
          ),
          boxShadow: AppGlows.small(strength: 0.6),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.xs + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.diamond_outlined,
                size: HomeEpic032Spec.headerIcon,
                color: AppColors.gold.withValues(alpha: 0.78),
              ),
              SizedBox(width: AppSpacing.xs + 2),
              Text(
                count,
                style: AppTypography.caption.copyWith(
                  color: AppColors.goldLight.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
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
