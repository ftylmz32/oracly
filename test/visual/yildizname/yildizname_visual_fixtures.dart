/// Phase 7A — deterministic Yıldızname visual fixtures (no provider / ephemeris).
library;

import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/models/star_map_reading.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_section.dart';

import '../../support/yildizname_result_fixtures.dart';

/// Fixed birth profile for hub_with_birth goldens (no live astronomy paint).
BirthProfile yildiznameVisualBirthProfile() => BirthProfile(
      birthDate: DateTime.utc(1995, 8, 15),
      birthPlace: 'İstanbul',
      birthTime: DateTime.utc(1995, 8, 15, 14, 30),
      birthTimeKnown: true,
      latitude: 41.01,
      longitude: 28.98,
      timezoneId: 'Europe/Istanbul',
    );

List<StarMapResultSection> yildiznameVisualLegacySections() => const [
      StarMapResultSection(
        title: 'Gökyüzü Mesajı',
        body: 'Bugün sakin bir nefes al. Arşiv sessizce yanında.',
      ),
      StarMapResultSection(
        title: 'Anlam',
        body: 'İç sesini dinle; acele etme.',
      ),
    ];

List<StarMapPlanetInfluence> yildiznameVisualLegacyPlanets() => const [
      StarMapPlanetInfluence(
        nameTr: 'Güneş',
        influence: 'odak',
        explanation: 'Sembolik Aslan enerjisi — katalog yorumu.',
        polarity: StarMapPolarity.balanced,
      ),
    ];

/// Mirrors CURRENT Narrative adapter titles (raw English / enum names).
List<StarMapResultSection> yildiznameVisualNarrativeReducedSections() => const [
      StarMapResultSection(
        title: 'summary',
        body: 'Güneş Leo konumunda sabırlı bir odak taşır.',
      ),
      StarMapResultSection(
        title: 'coreIdentity',
        body: 'Kimlik alanında sakin bir netlik aranıyor.',
      ),
      StarMapResultSection(
        title: 'reflection',
        body: 'Bugün hangi odak sana daha dürüst geliyor?',
      ),
      StarMapResultSection(
        title: 'closing',
        body: 'Yavaşça kendi ritmine dön.',
      ),
    ];

List<StarMapResultSection> yildiznameVisualNarrativeFullSections() => const [
      StarMapResultSection(
        title: 'summary',
        body: 'Güneş, Ay ve Yükselen birlikte sabırlı bir kimlik ekseni kurar.',
      ),
      StarMapResultSection(
        title: 'coreIdentity',
        body: 'Doğum göğünde kimlik net ve sakin duruyor.',
      ),
      StarMapResultSection(
        title: 'emotionalWorld',
        body: 'Duygusal dünya yumuşak bir ritme çağırıyor.',
      ),
      StarMapResultSection(
        title: 'anglesAndHouses',
        body: 'Açılar ve evler derinleşmeyi destekliyor.',
      ),
      StarMapResultSection(
        title: 'reflection',
        body: 'Hangi katman sana en dürüst geliyor?',
      ),
      StarMapResultSection(
        title: 'closing',
        body: 'Arşiv kapanır; sen kendi ritmine dönersin.',
      ),
    ];

/// Phase 7B — real sealed Narrative artifact carrying the SAME prose as the
/// 7A `yildiznameVisualNarrative*Sections` fixtures, so the reopen delta
/// against the 7A baseline is chrome only.
YildiznameArtifact yildiznameVisualNarrativeArtifact({
  required String id,
  required bool full,
}) =>
    full
        ? yildiznameFixtureNarrativeArtifact(
            id: id,
            scope: YildiznameNarrativeScope.full,
            kinds: const [
              YildiznameSectionKind.coreIdentity,
              YildiznameSectionKind.emotionalWorld,
              YildiznameSectionKind.anglesAndHouses,
            ],
            summary:
                'Güneş, Ay ve Yükselen birlikte sabırlı bir kimlik ekseni kurar.',
            sectionTexts: const [
              'Doğum göğünde kimlik net ve sakin duruyor.',
              'Duygusal dünya yumuşak bir ritme çağırıyor.',
              'Açılar ve evler derinleşmeyi destekliyor.',
            ],
            reflection: 'Hangi katman sana en dürüst geliyor?',
            closing: 'Arşiv kapanır; sen kendi ritmine dönersin.',
            createdAtUtc: DateTime.utc(2026, 1, 11),
          )
        : yildiznameFixtureNarrativeArtifact(
            id: id,
            scope: YildiznameNarrativeScope.reduced,
            kinds: const [YildiznameSectionKind.coreIdentity],
            sectionTexts: const [
              'Kimlik alanında sakin bir netlik aranıyor.',
            ],
            createdAtUtc: DateTime.utc(2026, 1, 10),
          );
