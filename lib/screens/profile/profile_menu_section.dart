/// OR-1120 — Journey hub navigation — organized by universe realms.
library;

import 'package:flutter/material.dart';

import '../../../core/modules/oracly_feature_id.dart';
import '../../../core/modules/oracly_feature_navigation.dart';
import '../../../core/navigation/universe/universe_navigation_copy.dart';
import '../../../features/premium/presentation/widgets/settings_tiles.dart';

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionHeader(title: UniverseNavigationCopy.sectionRemember),
        SettingsNavTile(
          icon: Icons.auto_stories_rounded,
          title: 'Geçmiş',
          subtitle: 'Tarot açılım günlüğün',
          onTap: () => OraclyFeatureNavigation.open(
            context,
            OraclyFeatureId.readingHistory,
          ),
        ),
        SettingsNavTile(
          icon: Icons.favorite_border_rounded,
          title: 'Kişisel Yansımalar',
          subtitle: 'Yolculuğunun nazik özeti',
          onTap: () => OraclyFeatureNavigation.open(
            context,
            OraclyFeatureId.personalInsights,
          ),
        ),
        SettingsNavTile(
          icon: Icons.psychology_outlined,
          title: 'Hafıza',
          subtitle: 'OR\'ın seninle paylaştığı kayıtlar',
          onTap: () => OraclyFeatureNavigation.open(
            context,
            OraclyFeatureId.memory,
          ),
        ),
        const SettingsSectionHeader(title: UniverseNavigationCopy.sectionGrow),
        SettingsNavTile(
          icon: Icons.emoji_events_outlined,
          title: 'Başarımlar',
          subtitle: 'Ruhsal yolculuk rozetlerin',
          onTap: () => OraclyFeatureNavigation.open(
            context,
            OraclyFeatureId.achievements,
          ),
        ),
        const SettingsSectionHeader(title: UniverseNavigationCopy.sectionAccount),
        SettingsNavTile(
          icon: Icons.workspace_premium_outlined,
          title: 'Premium',
          subtitle: 'Tüm özelliklerin kilidini aç',
          onTap: () => OraclyFeatureNavigation.open(
            context,
            OraclyFeatureId.premium,
          ),
        ),
        SettingsNavTile(
          icon: Icons.settings_outlined,
          title: 'Ayarlar',
          subtitle: 'Tema, bildirimler ve gizlilik',
          onTap: () => OraclyFeatureNavigation.open(
            context,
            OraclyFeatureId.settings,
          ),
        ),
      ],
    );
  }
}
