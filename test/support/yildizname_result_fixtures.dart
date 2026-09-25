/// Phase 7B — deterministic Yıldızname result fixtures (no provider, no
/// ephemeris). Requests mirror what `YildiznameRequestFactory` really emits
/// per scope, so scope-resolution tests exercise realistic evidence.
library;

import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_source.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_angle_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_aspect_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_balance_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_house_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_request.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_placement_fact.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_section.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_structured_result.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/narrative/versions.dart';

const _balances = [
  YildiznameBalanceFact(
    factRef: 'balance.elements',
    kind: 'elements',
    counts: {'fire': 3, 'earth': 1, 'air': 2, 'water': 1},
    dominant: 'fire',
  ),
  YildiznameBalanceFact(
    factRef: 'balance.modalities',
    kind: 'modalities',
    counts: {'cardinal': 2, 'fixed': 3, 'mutable': 2},
    dominant: 'fixed',
  ),
];

/// Request shaped like the real factory output for [scope].
///
/// For FULL, [ascendant] / [midheaven] / [houses] / [aspects] toggle whether
/// that layer is present; absent layers are listed in `omittedLayers` exactly
/// as the real request extras do.
YildiznameNarrativeRequest yildiznameFixtureRequest({
  required YildiznameNarrativeScope scope,
  String? fidelity,
  bool ascendant = true,
  bool midheaven = true,
  bool houses = true,
  bool aspects = true,
  String languageCode = 'tr',
}) {
  switch (scope) {
    case YildiznameNarrativeScope.legacy:
      return YildiznameNarrativeRequest(
        languageCode: languageCode,
        scope: scope,
        fidelity: fidelity ?? 'tropicalSunSign',
        calculationVersion: 'calc-fixture',
        placements: const [
          YildiznamePlacementFact(
            factRef: 'placement.sun',
            body: 'sun',
            sign: 'leo',
            certainty: 'exact',
          ),
        ],
        angles: const [],
        houses: const [],
        aspects: const [],
        balances: const [],
        discoveryThemes: const [],
        omittedLayers: const [
          'moon',
          'exactDegrees',
          'ascendant',
          'midheaven',
          'houses',
          'aspects',
          'personalPlanets',
        ],
      );
    case YildiznameNarrativeScope.reduced:
      return YildiznameNarrativeRequest(
        languageCode: languageCode,
        scope: scope,
        fidelity: fidelity ?? 'reducedNatal',
        calculationVersion: 'calc-fixture',
        placements: const [
          YildiznamePlacementFact(
            factRef: 'placement.sun',
            body: 'sun',
            sign: 'leo',
            certainty: 'intervalStable',
          ),
          YildiznamePlacementFact(
            factRef: 'placement.mercury',
            body: 'mercury',
            sign: 'virgo',
            certainty: 'intervalStable',
          ),
        ],
        angles: const [],
        houses: const [],
        aspects: const [],
        balances: _balances,
        discoveryThemes: const [],
        omittedLayers: const [
          'exactDegrees',
          'ascendant',
          'midheaven',
          'houses',
          'aspects',
          'retrograde',
          'ambiguous.moon',
        ],
      );
    case YildiznameNarrativeScope.full:
      return YildiznameNarrativeRequest(
        languageCode: languageCode,
        scope: scope,
        fidelity: fidelity ?? 'fullNatalEphemeris',
        houseSystem: 'wholeSign',
        calculationVersion: 'calc-fixture',
        placements: const [
          YildiznamePlacementFact(
            factRef: 'placement.sun',
            body: 'sun',
            sign: 'leo',
            certainty: 'exact',
            degreeWithinSign: 22.4,
            retrograde: false,
            house: 10,
          ),
          YildiznamePlacementFact(
            factRef: 'placement.moon',
            body: 'moon',
            sign: 'taurus',
            certainty: 'exact',
            degreeWithinSign: 3.1,
            retrograde: false,
            house: 7,
          ),
        ],
        angles: [
          if (ascendant)
            const YildiznameAngleFact(
              factRef: 'angle.ascendant',
              kind: 'ascendant',
              sign: 'scorpio',
              certainty: 'exact',
              degreeWithinSign: 11.2,
              house: 1,
            ),
          if (midheaven)
            const YildiznameAngleFact(
              factRef: 'angle.midheaven',
              kind: 'midheaven',
              sign: 'leo',
              certainty: 'exact',
              degreeWithinSign: 19.6,
              house: 10,
            ),
        ],
        houses: [
          if (houses)
            for (var n = 1; n <= 12; n++)
              YildiznameHouseFact(
                factRef: 'house.$n',
                number: n,
                sign: 'aries',
              ),
        ],
        aspects: [
          if (aspects)
            const YildiznameAspectFact(
              factRef: 'aspect.sun.moon.trine',
              bodyA: 'sun',
              bodyB: 'moon',
              type: 'trine',
              orb: 2.1,
            ),
        ],
        balances: _balances,
        discoveryThemes: const [],
        omittedLayers: [
          if (!ascendant) 'ascendant',
          if (!midheaven) 'midheaven',
          if (!houses) 'houses',
          if (!aspects) 'aspects',
        ],
      );
  }
}

YildiznameNarrativeStructuredResult yildiznameFixtureResult({
  YildiznameNarrativeScope scope = YildiznameNarrativeScope.reduced,
  List<YildiznameSectionKind> kinds = const [
    YildiznameSectionKind.coreIdentity,
  ],
  String languageCode = 'tr',
  String summary = 'Güneş Leo konumunda sabırlı bir odak taşır.',
  List<String>? sectionTexts,
  String reflection = 'Bugün hangi odak sana daha dürüst geliyor?',
  String closing = 'Yavaşça kendi ritmine dön.',
}) {
  YildiznameNarrativeBlock block(String text) => YildiznameNarrativeBlock(
    text: text,
    factRefs: const [],
    themeRefs: const [],
  );
  return YildiznameNarrativeStructuredResult(
    contractVersion: kYildiznameResultContractVersion,
    languageCode: languageCode,
    scope: scope,
    summary: block(summary),
    sections: [
      for (var i = 0; i < kinds.length; i++)
        YildiznameNarrativeSection(
          kind: kinds[i],
          text: sectionTexts != null && i < sectionTexts.length
              ? sectionTexts[i]
              : 'Saklı ${i + 1}. bölüm yorumu sakin bir netlik taşır.',
          factRefs: const [],
          themeRefs: const [],
        ),
    ],
    reflectionPrompt: block(reflection),
    closingMessage: block(closing),
  );
}

/// A sealed Narrative artifact built from a real request + result.
YildiznameArtifact yildiznameFixtureNarrativeArtifact({
  String id = 'yid_cccccccccccccccccccccccccccccccc',
  YildiznameNarrativeScope scope = YildiznameNarrativeScope.reduced,
  List<YildiznameSectionKind>? kinds,
  bool ascendant = true,
  bool midheaven = true,
  bool houses = true,
  bool aspects = true,
  String languageCode = 'tr',
  String summary = 'Güneş Leo konumunda sabırlı bir odak taşır.',
  List<String>? sectionTexts,
  String reflection = 'Bugün hangi odak sana daha dürüst geliyor?',
  String closing = 'Yavaşça kendi ritmine dön.',
  DateTime? createdAtUtc,
}) {
  final request = yildiznameFixtureRequest(
    scope: scope,
    ascendant: ascendant,
    midheaven: midheaven,
    houses: houses,
    aspects: aspects,
    languageCode: languageCode,
  );
  final result = yildiznameFixtureResult(
    scope: scope,
    kinds:
        kinds ??
        (scope == YildiznameNarrativeScope.full
            ? const [
                YildiznameSectionKind.coreIdentity,
                YildiznameSectionKind.emotionalWorld,
                YildiznameSectionKind.anglesAndHouses,
              ]
            : const [YildiznameSectionKind.coreIdentity]),
    languageCode: languageCode,
    summary: summary,
    sectionTexts: sectionTexts,
    reflection: reflection,
    closing: closing,
  );
  return YildiznameArtifactFactory.createNarrative(
    ownerId: 'fixture-owner',
    request: request,
    result: result,
    semanticFingerprint: 'sem-fixture',
    evidenceFingerprint: 'ev-fixture',
    createdAtUtc: createdAtUtc ?? DateTime.utc(2026, 1, 10),
    id: id,
  );
}

/// Narrative artifact with arbitrary stored metadata / payload — for
/// conflicting, incomplete, or future-shaped evidence. Integrity is not
/// sealed: presentation never verifies, and reopen tests use real artifacts.
YildiznameArtifact yildiznameFixtureRawNarrativeArtifact({
  required Map<String, dynamic> payload,
  String id = 'yid_eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
  String? scope,
  String? fidelity,
  String? resultLocale = 'tr',
}) {
  return YildiznameArtifact(
    id: id,
    ownerId: 'fixture-owner',
    createdAtUtc: DateTime.utc(2026, 1, 12),
    source: YildiznameArtifactSource.narrativeV1,
    resultLocale: resultLocale,
    scope: scope,
    fidelity: fidelity,
    contentHash: 'raw',
    semanticDedupeKey: 'raw',
    payload: payload,
  );
}
