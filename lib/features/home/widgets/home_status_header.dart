/// EPIC-022 / EPIC-028 — Reference status bar: menu · official logo · premium.
library;

import 'package:flutter/material.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/brand/oracly_brand_mark.dart';
import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/oracly_header_action.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../theme/home_composition.dart';

/// Status header — hamburger left, official mark + ORACLY, premium crown right.
class HomeStatusHeader extends StatelessWidget {
  const HomeStatusHeader({
    super.key,
    this.onPremiumTap,
    this.onMenuTap,
  });

  final VoidCallback? onPremiumTap;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeComposition.statusHeaderHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: AppLayout.headerSideMinWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: OraclyHeaderAction(
                icon: Icons.menu_rounded,
                label: OraclyL10n.t('nav.menu'),
                onTap: onMenuTap ??
                    () => OraclyNavigationService.openSettings(context),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: OraclyA11y.chromeTextScale(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ExcludeSemantics(
                      child: OraclyBrandMark(size: 22, forLauncher: true),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      header: true,
                      label: 'ORACLY',
                      child: Text(
                        'ORACLY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headingM.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          color: OraclyA11y.goldReadable(AppColors.goldLight),
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: AppLayout.headerSideMinWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: OraclyHeaderAction(
                icon: Icons.workspace_premium_rounded,
                label: OraclyL10n.t('settings.premium'),
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
