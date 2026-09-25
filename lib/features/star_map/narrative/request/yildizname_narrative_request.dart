/// Safe Yıldızname Narrative V1 request — provider-facing facts only.
library;

import '../versions.dart';
import 'yildizname_angle_fact.dart';
import 'yildizname_aspect_fact.dart';
import 'yildizname_balance_fact.dart';
import 'yildizname_house_fact.dart';
import 'yildizname_narrative_policy.dart';
import 'yildizname_narrative_scope.dart';
import 'yildizname_placement_fact.dart';
import 'yildizname_theme_fact.dart';

final class YildiznameNarrativeRequest {
  YildiznameNarrativeRequest({
    required this.languageCode,
    required this.scope,
    required this.fidelity,
    required List<YildiznamePlacementFact> placements,
    required List<YildiznameAngleFact> angles,
    required List<YildiznameHouseFact> houses,
    required List<YildiznameAspectFact> aspects,
    required List<YildiznameBalanceFact> balances,
    required List<YildiznameThemeFact> discoveryThemes,
    required List<String> omittedLayers,
    this.houseSystem,
    this.calculationVersion,
    this.version = kYildiznameNarrativeVersion,
    this.serializerVersion = kYildiznameSerializerVersion,
  })  : placements = List.unmodifiable(placements),
        angles = List.unmodifiable(angles),
        houses = List.unmodifiable(houses),
        aspects = List.unmodifiable(aspects),
        balances = List.unmodifiable(balances),
        discoveryThemes = List.unmodifiable(discoveryThemes),
        omittedLayers = List.unmodifiable(omittedLayers);

  final int version;
  final int serializerVersion;
  final String languageCode;
  final YildiznameNarrativeScope scope;
  final String fidelity;
  final String? houseSystem;
  final String? calculationVersion;
  final List<YildiznamePlacementFact> placements;
  final List<YildiznameAngleFact> angles;
  final List<YildiznameHouseFact> houses;
  final List<YildiznameAspectFact> aspects;
  final List<YildiznameBalanceFact> balances;
  final List<YildiznameThemeFact> discoveryThemes;
  final List<String> omittedLayers;

  Set<String> get factRefs => {
        for (final p in placements) p.factRef,
        for (final a in angles) a.factRef,
        for (final h in houses) h.factRef,
        for (final a in aspects) a.factRef,
        for (final b in balances) b.factRef,
      };

  Set<String> get themeRefs => {for (final t in discoveryThemes) t.themeRef};

  Map<String, dynamic> toProviderJson() => {
        'version': version,
        'serializerVersion': serializerVersion,
        'languageCode': languageCode,
        'scope': scope.wireName,
        'fidelity': fidelity,
        if (houseSystem != null) 'houseSystem': houseSystem,
        if (calculationVersion != null)
          'calculationVersion': calculationVersion,
        'placements': placements.map((e) => e.toProviderJson()).toList(),
        'angles': angles.map((e) => e.toProviderJson()).toList(),
        'houses': houses.map((e) => e.toProviderJson()).toList(),
        'aspects': aspects.map((e) => e.toProviderJson()).toList(),
        'balances': balances.map((e) => e.toProviderJson()).toList(),
        'discoveryThemes':
            discoveryThemes.map((e) => e.toProviderJson()).toList(),
        'omittedLayers': List<String>.from(omittedLayers),
        'policy': YildiznameNarrativePolicy.toProviderJson(),
      };
}
