/// OR-438 — Central module catalogue — add modules here, wire UI when ready.
library;

import 'package:flutter/material.dart';

import '../../features/oracle_engine/core/oracle_engine_type.dart';
import '../../features/prompt_engine/core/prompt_domain.dart';
import '../constants/app_assets.dart';
import '../navigation/oracly_routes.dart';
import '../navigation/universe/oracly_universe_realm.dart';
import '../settings/settings_schema.dart';
import 'oracly_feature_availability.dart';
import 'oracly_feature_id.dart';
import 'oracly_feature_module.dart';

/// Read-only registry of all Oracly modules — live and reserved.
abstract final class OraclyFeatureRegistry {
  OraclyFeatureRegistry._();

  static const _all = <OraclyFeatureModule>[
    OraclyFeatureModule(
      id: OraclyFeatureId.tarot,
      title: 'Tarot',
      availability: OraclyFeatureAvailability.live,
      routeName: OraclyRoutes.tarot,
      icon: Icons.style,
      iconAsset: AppAssets.featureTarot,
      engineType: OracleEngineType.tarot,
      promptDomain: PromptDomain.tarot,
      contentCatalogueId: 'tarot',
      homeBand: 'explore',
      universeRealm: OraclyUniverseRealm.explore,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.coffee,
      title: 'Kahve',
      subtitle: 'Fincan fotoğrafı ve yorum',
      availability: OraclyFeatureAvailability.live,
      routeName: OraclyRoutes.coffee,
      icon: Icons.local_cafe_rounded,
      homeBand: 'explore',
      universeRealm: OraclyUniverseRealm.explore,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.palm,
      title: 'El',
      subtitle: 'Avuç fotoğrafı ve sembolik yorum',
      availability: OraclyFeatureAvailability.live,
      routeName: OraclyRoutes.palm,
      icon: Icons.back_hand_outlined,
      universeRealm: OraclyUniverseRealm.explore,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.soulMate,
      title: 'Ruh Eşi',
      subtitle: 'Sembolik portre deneyimi',
      availability: OraclyFeatureAvailability.live,
      requiresPremium: true,
      icon: Icons.auto_awesome_outlined,
      homeBand: 'explore',
      universeRealm: OraclyUniverseRealm.explore,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.aiChat,
      title: 'OR',
      subtitle: 'Yansıma ve sohbet',
      availability: OraclyFeatureAvailability.live,
      routeName: OraclyRoutes.chat,
      icon: Icons.auto_awesome_rounded,
      iconAsset: AppAssets.featureAiCrystal,
      homeBand: 'reflect',
      universeRealm: OraclyUniverseRealm.reflect,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.dailyEnergy,
      title: 'Bugünkü Ayin',
      subtitle: 'Kart ve yansıma',
      availability: OraclyFeatureAvailability.live,
      routeName: OraclyRoutes.dailyEnergy,
      engineType: OracleEngineType.dailyEnergy,
      promptDomain: PromptDomain.dailyEnergy,
      contentCatalogueId: 'daily_energy',
      universeRealm: OraclyUniverseRealm.explore,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.dream,
      title: 'Rüya',
      subtitle: 'Önizleme · sembol kataloğu',
      availability: OraclyFeatureAvailability.preview,
      routeName: OraclyRoutes.dream,
      icon: Icons.nightlight_round,
      iconAsset: AppAssets.featureDream,
      engineType: OracleEngineType.dream,
      promptDomain: PromptDomain.dream,
      contentCatalogueId: 'dream',
      homeBand: 'understand',
      universeRealm: OraclyUniverseRealm.understand,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.astrology,
      title: 'Astroloji',
      subtitle: 'Önizleme · Güneş burcu okuması',
      availability: OraclyFeatureAvailability.preview,
      routeName: OraclyRoutes.astrology,
      icon: Icons.auto_awesome,
      iconAsset: AppAssets.featureAstrology,
      engineType: OracleEngineType.astrology,
      promptDomain: PromptDomain.astrology,
      contentCatalogueId: 'astrology',
      homeBand: 'understand',
      universeRealm: OraclyUniverseRealm.understand,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.starMap,
      title: 'Yıldızname',
      subtitle: 'Yerel · kişisel hikâye arşivi',
      availability: OraclyFeatureAvailability.preview,
      routeName: OraclyRoutes.starMap,
      icon: Icons.star_outline_rounded,
      iconAsset: AppAssets.featureStarMap,
      homeBand: 'understand',
      universeRealm: OraclyUniverseRealm.understand,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.readingHistory,
      title: 'Geçmiş Açılımlar',
      subtitle: 'Tarot arşivin',
      availability: OraclyFeatureAvailability.live,
      routeName: OraclyRoutes.readingHistory,
      icon: Icons.menu_book_rounded,
      universeRealm: OraclyUniverseRealm.remember,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.discoveryJournal,
      title: 'Keşif Günlüğü',
      subtitle: 'Biriken deneyimlerin',
      availability: OraclyFeatureAvailability.live,
      routeName: OraclyRoutes.discoveryJournal,
      icon: Icons.auto_stories_outlined,
      universeRealm: OraclyUniverseRealm.remember,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.dailyMessage,
      title: 'Günün Mesajı',
      subtitle: 'Bugün için sakin bir yansıma',
      availability: OraclyFeatureAvailability.live,
      routeName: OraclyRoutes.dailyMessage,
      icon: Icons.wb_twilight_outlined,
      universeRealm: OraclyUniverseRealm.explore,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.personalInsights,
      title: 'Kişisel Yansımalar',
      subtitle: 'Yolculuğunun nazik özeti',
      availability: OraclyFeatureAvailability.live,
      routeName: OraclyRoutes.personalInsights,
      icon: Icons.favorite_border_rounded,
      universeRealm: OraclyUniverseRealm.reflect,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.memory,
      title: 'Hafıza',
      subtitle: 'OR\'ın hatırladıkları',
      availability: OraclyFeatureAvailability.live,
      icon: Icons.psychology_outlined,
      universeRealm: OraclyUniverseRealm.remember,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.achievements,
      title: 'Başarımlar',
      subtitle: 'Ruhsal yolculuk rozetlerin',
      availability: OraclyFeatureAvailability.reserved,
      routeName: OraclyRoutes.achievements,
      icon: Icons.emoji_events_outlined,
      universeRealm: OraclyUniverseRealm.grow,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.premium,
      title: 'Premium',
      availability: OraclyFeatureAvailability.live,
      routeName: OraclyRoutes.premium,
      requiresPremium: false,
      universeRealm: OraclyUniverseRealm.account,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.settings,
      title: 'Ayarlar',
      availability: OraclyFeatureAvailability.live,
      routeName: OraclyRoutes.settings,
      icon: Icons.settings_outlined,
      universeRealm: OraclyUniverseRealm.account,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.numerology,
      title: 'Numeroloji',
      subtitle: 'Sayıların dili',
      availability: OraclyFeatureAvailability.reserved,
      routeName: OraclyRoutes.numerology,
      icon: Icons.pin_outlined,
      engineType: OracleEngineType.numerology,
      promptDomain: PromptDomain.numerology,
      contentCatalogueId: 'numerology',
      homeBand: 'understand',
      universeRealm: OraclyUniverseRealm.understand,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.moonCalendar,
      title: 'Ay Takvimi',
      subtitle: 'Döngüler ve ritim',
      availability: OraclyFeatureAvailability.reserved,
      routeName: OraclyRoutes.moonCalendar,
      icon: Icons.brightness_2_outlined,
      contentCatalogueId: 'moon_calendar',
      settingsKeys: [SettingsSchema.moonNotifications],
      homeBand: 'understand',
      universeRealm: OraclyUniverseRealm.understand,
    ),
    OraclyFeatureModule(
      id: OraclyFeatureId.manifestation,
      title: 'Manifestasyon',
      subtitle: 'Niyet ve odak',
      availability: OraclyFeatureAvailability.reserved,
      routeName: OraclyRoutes.manifestation,
      icon: Icons.auto_awesome_outlined,
      contentCatalogueId: 'manifestation',
      homeBand: 'understand',
      universeRealm: OraclyUniverseRealm.understand,
    ),
  ];

  static List<OraclyFeatureModule> get all => List.unmodifiable(_all);

  static OraclyFeatureModule? byId(OraclyFeatureId id) {
    for (final module in _all) {
      if (module.id == id) return module;
    }
    return null;
  }

  static OraclyFeatureModule? byRoute(String? routeName) {
    if (routeName == null) return null;
    for (final module in _all) {
      if (module.routeName == routeName) return module;
    }
    return null;
  }

  static List<OraclyFeatureModule> get live =>
      _all.where((m) => m.isLive).toList(growable: false);

  static List<OraclyFeatureModule> get preview =>
      _all.where((m) => m.isPreview).toList(growable: false);

  static List<OraclyFeatureModule> get reserved =>
      _all.where((m) => m.isReserved).toList(growable: false);

  static List<OraclyFeatureModule> forHomeBand(String band) => _all
      .where(
        (m) =>
            m.homeBand == band &&
            (m.isLive || m.isPreview),
      )
      .toList(growable: false);

  static List<OraclyFeatureModule> forRealm(OraclyUniverseRealm realm) => _all
      .where(
        (m) =>
            m.universeRealm == realm &&
            (m.isLive || m.isPreview),
      )
      .toList(growable: false);

  static List<OraclyFeatureModule> withEngine(OracleEngineType type) => _all
      .where((m) => m.engineType == type)
      .toList(growable: false);
}
