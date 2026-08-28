/// OR-1120 — Reusable feature hub layout.
library;

import 'package:flutter/material.dart';

import '../../core/design_system/hero_art/hero_art.dart';
import '../../core/design_system/oracly_app_bar.dart';
import '../../core/design_system/oracly_chrome.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/oracly_visual_rebirth.dart';
import '../../shared/widgets/oracly_button.dart';
import '../../shared/widgets/oracly_entrance.dart';
import '../../shared/widgets/oracly_gold_button.dart';
import '../../shared/widgets/oracly_luxury_surface.dart';
import '../../shared/widgets/oracly_scroll_body.dart';
import '../../shared/widgets/oracly_scaffold.dart';

class FeatureHubScreen extends StatelessWidget {
  const FeatureHubScreen({
    super.key,
    required this.title,
    required this.headline,
    required this.description,
    required this.icon,
    this.iconAsset,
    this.heroArt,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.body,
  });

  final String title;
  final String headline;
  final String description;
  final IconData icon;
  final String? iconAsset;
  final Widget? heroArt;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      ambience: OraclyAmbience.celestial,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.paddingOf(context).top + OraclyChrome.headerHeight,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: OraclyChrome.screenPaddingH,
            child: OraclyAppBar.back(title: title),
          ),
        ),
      ),
      child: OraclyScrollBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (heroArt != null) ...[
              HeroArtViewport(child: heroArt!),
              SizedBox(height: AppSpacing.lg),
            ],
            OraclyEntrance(
              mode: OraclyEntranceMode.softScale,
              child: OraclyLuxurySurface(
                tier: OraclyLuxuryTier.featured,
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (heroArt == null)
                      Icon(icon, size: 40, color: AppColors.goldLight),
                    if (heroArt == null) SizedBox(height: AppSpacing.md),
                    Text(
                      headline,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (body != null) ...[
              SizedBox(height: AppSpacing.lg),
              OraclyEntrance.staggered(
                index: 1,
                child: body!,
              ),
            ],
            if (primaryLabel != null && onPrimary != null) ...[
              SizedBox(height: AppSpacing.lg),
              OraclyEntrance.staggered(
                index: 2,
                child: OraclyGoldButton(
                  label: primaryLabel!,
                  onPressed: onPrimary,
                  expanded: true,
                ),
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              SizedBox(height: AppSpacing.sm),
              OraclyEntrance.staggered(
                index: 3,
                child: OraclyButton(
                  text: secondaryLabel!,
                  type: OraclyButtonType.secondary,
                  isExpanded: true,
                  onPressed: onSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
