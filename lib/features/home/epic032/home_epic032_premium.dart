/// EPIC-032 — Approved premium banner.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../../../shared/widgets/oracly_gold_button.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'home_epic032_spec.dart';
import 'home_epic032_surface.dart';

class HomeEpic032Premium extends StatelessWidget {
  const HomeEpic032Premium({super.key, this.onExploreTap});

  final VoidCallback? onExploreTap;

  static const String _title = "Premium'u keşfet";
  static const String _description = 'Daha sakin bir yansıma odası.';
  static const String _ctaLabel = "Premium'u keşfet";

  void _handleTap(BuildContext context) {
    if (onExploreTap != null) {
      onExploreTap!();
      return;
    }
    OraclyNavigationService.openPremium(context);
  }

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: () => _handleTap(context),
      borderRadius: HomeEpic032Spec.premiumRadius,
      glowShift: true,
      child: HomeEpic032Surface(
        premium: true,
        borderRadius: HomeEpic032Spec.premiumRadius,
        padding: HomeEpic032Spec.premiumPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: HomeEpic032Spec.premiumMinHeight,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Padding(
                    padding: EdgeInsets.only(
                      right: HomeEpic032Spec.premiumCrown * 0.5,
                    ),
                    child: Text(
                      _description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.82),
                        height: 1.55,
                        letterSpacing: 0.15,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  OraclyGoldButton(
                    label: _ctaLabel,
                    expanded: true,
                    borderRadius: HomeEpic032Spec.premiumRadius,
                    onPressed: () => _handleTap(context),
                  ),
                ],
              ),
              Positioned(
                right: -4,
                bottom: -8,
                child: OraclyAssetImage(
                  assetPath: AppAssets.premiumBannerCrown,
                  width: HomeEpic032Spec.premiumCrown,
                  height: HomeEpic032Spec.premiumCrown,
                  fit: BoxFit.contain,
                  fallback: Icon(
                    Icons.workspace_premium_rounded,
                    size: HomeEpic032Spec.premiumCrown * 0.72,
                    color: AppColors.goldLight.withValues(alpha: 0.88),
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
