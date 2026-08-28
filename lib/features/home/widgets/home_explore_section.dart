/// EPIC-022 — Explore band: horizontal premium rows, never cramped.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/modules/oracly_feature_l10n.dart';
import '../../../core/modules/oracly_feature_module.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../core/modules/oracly_feature_registry.dart';
import '../../../core/navigation/universe/universe_navigation_copy.dart';
import '../../../core/theme/app_colors.dart';
import '../theme/home_composition.dart';
import '../theme/home_focus.dart';
import 'home_entrance.dart';
import 'mystic_feature_card.dart';

/// Horizontal explore rows for reflect + understand universe bands.
class HomeExploreSection extends StatelessWidget {
  const HomeExploreSection({
    super.key,
    this.entranceDelayMs = 0,
  });

  final int entranceDelayMs;

  @override
  Widget build(BuildContext context) {
    final reflect = OraclyFeatureRegistry.forHomeBand('reflect');
    final understand = OraclyFeatureRegistry.forHomeBand('understand');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reflect.isNotEmpty)
          _HorizontalBand(
            label: UniverseNavigationCopy.bandReflect,
            hint: UniverseNavigationCopy.bandReflectHint,
            modules: reflect,
            focusZone: HomeFocusZone.ai,
            entranceDelayMs: entranceDelayMs,
          ),
        if (reflect.isNotEmpty && understand.isNotEmpty)
          SizedBox(height: HomeComposition.exploreBandGap),
        if (understand.isNotEmpty)
          _HorizontalBand(
            label: UniverseNavigationCopy.bandUnderstand,
            modules: understand,
            focusZone: HomeFocusZone.cosmic,
            entranceDelayMs: entranceDelayMs + 120,
            cardWidth: HomeComposition.exploreCardWidthWide,
          ),
      ],
    );
  }
}

class _HorizontalBand extends StatelessWidget {
  const _HorizontalBand({
    required this.label,
    required this.modules,
    required this.focusZone,
    required this.entranceDelayMs,
    this.hint,
    this.cardWidth,
  });

  final String label;
  final String? hint;
  final List<OraclyFeatureModule> modules;
  final HomeFocusZone focusZone;
  final int entranceDelayMs;
  final double? cardWidth;

  @override
  Widget build(BuildContext context) {
    final width = cardWidth ?? HomeComposition.exploreCardWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.72),
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hint != null) ...[
                SizedBox(height: AppSpacing.s4),
                Text(
                  hint!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.55),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: HomeComposition.labelToContent),
        SizedBox(
          height: HomeComposition.exploreRowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            itemCount: modules.length,
            separatorBuilder: (_, _) => SizedBox(width: HomeComposition.tileGap),
            itemBuilder: (context, index) {
              final module = modules[index];
              return SizedBox(
                width: width,
                child: HomeEntrance(
                  delay: Duration(milliseconds: entranceDelayMs + index * 60),
                  child: HomeFocusRegion(
                    zone: focusZone,
                    interactive: true,
                    child: MysticFeatureCard(
                      icon: module.icon ?? Icons.auto_awesome_rounded,
                      iconAsset: module.iconAsset,
                      title: module.labeled,
                      compact: true,
                      tier: HomeVisualTier.whisper,
                      focusZone: focusZone,
                      onTap: () =>
                          OraclyFeatureNavigation.open(context, module.id),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
