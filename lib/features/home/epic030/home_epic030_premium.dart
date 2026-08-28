/// EPIC-030 — Approved Home premium upsell card.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../../../shared/widgets/oracly_gold_button.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'home_epic030_spec.dart';
import 'home_epic030_surface.dart';

class HomeEpic030Premium extends StatelessWidget {
  const HomeEpic030Premium({super.key, this.onExploreTap});

  final VoidCallback? onExploreTap;

  static const String _title = "Premium'u keşfet";
  static const String _body = 'Daha sakin bir yansıma odası.';
  static const String _cta = "Premium'u keşfet";

  void _open(BuildContext context) {
    if (onExploreTap != null) {
      onExploreTap!();
      return;
    }
    OraclyNavigationService.openPremium(context);
  }

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: () => _open(context),
      borderRadius: HomeEpic030Spec.premiumRadius,
      glowShift: true,
      child: HomeEpic030Surface(
        premium: true,
        borderRadius: HomeEpic030Spec.premiumRadius,
        padding: HomeEpic030Spec.premiumPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: HomeEpic030Spec.premiumMinHeight,
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
                      right: HomeEpic030Spec.premiumCrown * 0.5,
                    ),
                    child: Text(
                      _body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.82),
                        height: 1.55,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  OraclyGoldButton(
                    label: _cta,
                    expanded: true,
                    borderRadius: HomeEpic030Spec.premiumRadius,
                    onPressed: () => _open(context),
                  ),
                ],
              ),
              Positioned(
                right: -4,
                bottom: -8,
                child: OraclyAssetImage(
                  assetPath: AppAssets.premiumBannerCrown,
                  width: HomeEpic030Spec.premiumCrown,
                  height: HomeEpic030Spec.premiumCrown,
                  fit: BoxFit.contain,
                  fallback: Icon(
                    Icons.workspace_premium_rounded,
                    size: HomeEpic030Spec.premiumCrown * 0.72,
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
