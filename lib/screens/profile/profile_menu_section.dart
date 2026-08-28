/// OR-1120 — Journey hub navigation — organized by universe realms.
library;

import 'package:flutter/material.dart';

import '../../../core/modules/oracly_feature_id.dart';
import '../../../core/modules/oracly_feature_l10n.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../core/modules/oracly_feature_registry.dart';
import '../../../core/navigation/universe/universe_navigation_copy.dart';
import '../../../features/premium/presentation/widgets/settings_tiles.dart';

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    final history = OraclyFeatureRegistry.byId(OraclyFeatureId.readingHistory)!;
    final insights = OraclyFeatureRegistry.byId(
      OraclyFeatureId.personalInsights,
    )!;
    final memory = OraclyFeatureRegistry.byId(OraclyFeatureId.memory)!;
    final grow = OraclyFeatureRegistry.byId(OraclyFeatureId.achievements)!;
    final premium = OraclyFeatureRegistry.byId(OraclyFeatureId.premium)!;
    final settings = OraclyFeatureRegistry.byId(OraclyFeatureId.settings)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(title: UniverseNavigationCopy.sectionRemember),
        SettingsNavTile(
          icon: Icons.auto_stories_rounded,
          title: history.labeled,
          subtitle: history.labeledSubtitle ?? '',
          onTap: () => OraclyFeatureNavigation.open(
            context,
            OraclyFeatureId.readingHistory,
          ),
        ),
        SettingsNavTile(
          icon: Icons.favorite_border_rounded,
          title: insights.labeled,
          subtitle: insights.labeledSubtitle ?? '',
          onTap: () => OraclyFeatureNavigation.open(
            context,
            OraclyFeatureId.personalInsights,
          ),
        ),
        SettingsNavTile(
          icon: Icons.psychology_outlined,
          title: memory.labeled,
          subtitle: memory.labeledSubtitle ?? '',
          onTap: () =>
              OraclyFeatureNavigation.open(context, OraclyFeatureId.memory),
        ),
        SettingsSectionHeader(title: UniverseNavigationCopy.sectionGrow),
        SettingsNavTile(
          icon: Icons.emoji_events_outlined,
          title: grow.labeled,
          subtitle: grow.labeledSubtitle ?? '',
          onTap: () => OraclyFeatureNavigation.open(
            context,
            OraclyFeatureId.achievements,
          ),
        ),
        SettingsSectionHeader(title: UniverseNavigationCopy.sectionAccount),
        SettingsNavTile(
          icon: Icons.workspace_premium_outlined,
          title: premium.labeled,
          subtitle: premium.labeledSubtitle ?? '',
          onTap: () =>
              OraclyFeatureNavigation.open(context, OraclyFeatureId.premium),
        ),
        SettingsNavTile(
          icon: Icons.settings_outlined,
          title: settings.labeled,
          subtitle: settings.labeledSubtitle ?? '',
          onTap: () =>
              OraclyFeatureNavigation.open(context, OraclyFeatureId.settings),
        ),
      ],
    );
  }
}
