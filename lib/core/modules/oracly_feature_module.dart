/// OR-438 — Declarative module descriptor for UI, nav, engines, and premium.
library;

import 'package:flutter/material.dart';

import '../../features/oracle_engine/core/oracle_engine_type.dart';
import '../../features/prompt_engine/core/prompt_domain.dart';
import '../navigation/universe/oracly_universe_realm.dart';
import 'oracly_feature_availability.dart';
import 'oracly_feature_id.dart';

/// One installable Oracly module — single source for future discovery wiring.
class OraclyFeatureModule {
  const OraclyFeatureModule({
    required this.id,
    required this.title,
    required this.availability,
    this.subtitle,
    this.routeName,
    this.icon,
    this.iconAsset,
    this.engineType,
    this.promptDomain,
    this.contentCatalogueId,
    this.requiresPremium = false,
    this.settingsKeys = const [],
    this.homeBand,
    this.universeRealm,
  });

  final OraclyFeatureId id;
  final String title;
  final String? subtitle;
  final OraclyFeatureAvailability availability;
  final String? routeName;
  final IconData? icon;
  final String? iconAsset;

  /// Links to [OracleEngineFactory] when interpretation runs server-side.
  final OracleEngineType? engineType;

  /// Links to [PromptDomain] when AI prompts are composed.
  final PromptDomain? promptDomain;

  /// Links to `features/content/<id>/` catalogues.
  final String? contentCatalogueId;

  final bool requiresPremium;

  /// Keys in [SettingsSchema] owned by this module.
  final List<String> settingsKeys;

  /// Optional home portal band (`explore`, `reflect`, `understand`).
  final String? homeBand;

  /// Which universe realm this experience belongs to.
  final OraclyUniverseRealm? universeRealm;

  bool get isLive => availability == OraclyFeatureAvailability.live;
  bool get isPreview => availability == OraclyFeatureAvailability.preview;
  bool get isReserved => availability == OraclyFeatureAvailability.reserved;
  bool get isNavigable => routeName != null && !isReserved;
}
