/// Reference home — YANSIT band: title, divider, horizontal card.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_typography.dart';
import '../../../core/modules/oracly_feature_id.dart';
import '../../../core/modules/oracly_feature_module.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../core/modules/oracly_feature_registry.dart';
import '../../../core/navigation/universe/universe_navigation_copy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/oracly_signature_motifs.dart';
import '../theme/home_composition.dart';
import '../theme/home_focus.dart';
import 'home_entrance.dart';
import 'mystic_feature_card.dart';
import 'mystic_feature_grid.dart';

/// Reflection row — decorative title + wide premium card.
class HomeReflectionSection extends StatelessWidget {
  const HomeReflectionSection({
    super.key,
    this.entranceDelayMs = 0,
  });

  final int entranceDelayMs;

  @override
  Widget build(BuildContext context) {
    return MysticFeatureGrid(
      band: HomeCompositionBand.reflect,
      entranceDelayMs: entranceDelayMs,
    );
  }
}

/// Discover row — three equal vertical cards (understand band).
class HomeDiscoverSection extends StatelessWidget {
  const HomeDiscoverSection({
    super.key,
    this.entranceDelayMs = 0,
  });

  final int entranceDelayMs;

  static const _discoverIds = [
    OraclyFeatureId.dream,
    OraclyFeatureId.astrology,
    OraclyFeatureId.starMap,
  ];

  static List<OraclyFeatureModule> get _modules {
    return _discoverIds
        .map(OraclyFeatureRegistry.byId)
        .whereType<OraclyFeatureModule>()
        .where((m) => m.isLive || m.isPreview)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final modules = _modules;
    if (modules.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          UniverseNavigationCopy.bandExplore,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.72),
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const OraclySignatureDivider(compact: true),
        SizedBox(height: HomeComposition.labelToContent),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < modules.length; i++) ...[
              if (i > 0) SizedBox(width: HomeComposition.tileGap),
              Expanded(
                child: HomeEntrance(
                  delay: Duration(milliseconds: entranceDelayMs + i * 60),
                  child: HomeFocusRegion(
                    zone: HomeFocusZone.cosmic,
                    interactive: true,
                    child: MysticFeatureCard(
                      icon: modules[i].icon ?? Icons.auto_awesome_rounded,
                      iconAsset: modules[i].iconAsset,
                      title: modules[i].title,
                      tier: HomeVisualTier.whisper,
                      focusZone: HomeFocusZone.cosmic,
                      onTap: () =>
                          OraclyFeatureNavigation.open(context, modules[i].id),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
