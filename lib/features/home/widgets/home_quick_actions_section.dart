/// Reference home — 2×3 square feature grid (six equal tiles).
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/micro_details/micro_details.dart';
import '../../../core/modules/oracly_feature_id.dart';
import '../../../core/modules/oracly_feature_l10n.dart';
import '../../../core/modules/oracly_feature_module.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../core/modules/oracly_feature_registry.dart';
import '../theme/home_composition.dart';
import '../theme/home_focus.dart';
import 'quick_action_tile.dart';

/// Six square launchers — reference 2-column × 3-row grid.
class HomeQuickActionsSection extends StatelessWidget {
  const HomeQuickActionsSection({
    super.key,
    this.entranceDelayMs = 0,
  });

  final int entranceDelayMs;

  static const _featureIds = [
    OraclyFeatureId.tarot,
    OraclyFeatureId.dream,
    OraclyFeatureId.astrology,
    OraclyFeatureId.aiChat,
    OraclyFeatureId.readingHistory,
    OraclyFeatureId.memory,
  ];

  static List<OraclyFeatureModule> get _modules {
    return _featureIds
        .map(OraclyFeatureRegistry.byId)
        .whereType<OraclyFeatureModule>()
        .where((m) => m.isLive || m.isPreview)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final modules = _modules;
    if (modules.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : AppLayout.maxContentWidth - AppLayout.screenHorizontal * 2;
        final tileSize =
            (contentWidth - HomeComposition.tileGap) / 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: HomeComposition.tileGap,
            mainAxisSpacing: HomeComposition.tileGap,
            mainAxisExtent: tileSize,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            return MicroListReveal(
              index: index,
              baseDelay: Duration(milliseconds: entranceDelayMs),
              child: HomeFocusRegion(
                zone: HomeFocusZone.spread,
                interactive: true,
                child: QuickActionTile(
                  phase: index.toDouble(),
                  height: tileSize,
                  icon: module.icon ?? Icons.auto_awesome_rounded,
                  title: module.labeled,
                  onTap: () =>
                      OraclyFeatureNavigation.open(context, module.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
