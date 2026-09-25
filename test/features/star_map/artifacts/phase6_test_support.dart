/// Shared fixtures for Phase 6 artifact tests.
library;

import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_id.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_request.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_placement_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_section.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_structured_result.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/narrative/versions.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_result_section.dart';

/// Ephemeral storage used as FakeLocalStorage in Phase 6 tests.
LocalStorage fakeLocalStorage([Map<String, Object>? seed]) =>
    LocalStorage.ephemeral(seed);

LocalYildiznameArtifactRepository artifactRepo(
  LocalStorage storage,
  String? ownerId,
) =>
    LocalYildiznameArtifactRepository(storage, ownerId: ownerId);

void useFixedIds(List<String> ids) {
  var i = 0;
  YildiznameArtifactId.generator = () {
    if (i >= ids.length) {
      return YildiznameArtifactId.secure();
    }
    return ids[i++];
  };
}

void resetIds() {
  YildiznameArtifactId.generator = YildiznameArtifactId.secure;
}

YildiznameNarrativeRequest sampleRequest({
  List<YildiznameThemeFact> themes = const [],
  String fidelity = 'reducedNatal',
  String? calculationVersion = 'calc-v1',
}) {
  return YildiznameNarrativeRequest(
    languageCode: 'tr',
    scope: YildiznameNarrativeScope.reduced,
    fidelity: fidelity,
    calculationVersion: calculationVersion,
    placements: const [
      YildiznamePlacementFact(
        factRef: 'place.sun.leo',
        body: 'sun',
        sign: 'leo',
        certainty: 'high',
      ),
    ],
    angles: const [],
    houses: const [],
    aspects: const [],
    balances: const [],
    discoveryThemes: themes,
    omittedLayers: const ['angles', 'houses'],
  );
}

YildiznameNarrativeStructuredResult sampleResult({
  List<String> themeRefs = const [],
  String summary = 'Güneş Leo konumunda sabırlı bir odak taşır.',
}) {
  return YildiznameNarrativeStructuredResult(
    contractVersion: kYildiznameResultContractVersion,
    languageCode: 'tr',
    scope: YildiznameNarrativeScope.reduced,
    summary: YildiznameNarrativeBlock(
      text: summary,
      factRefs: const ['place.sun.leo'],
      themeRefs: themeRefs,
    ),
    sections: [
      YildiznameNarrativeSection(
        kind: YildiznameSectionKind.coreIdentity,
        text: 'Kimlik alanında sakin bir netlik aranıyor.',
        factRefs: const ['place.sun.leo'],
        themeRefs: themeRefs,
      ),
    ],
    reflectionPrompt: YildiznameNarrativeBlock(
      text: 'Bugün hangi odak sana daha dürüst geliyor?',
      factRefs: const [],
      themeRefs: const [],
    ),
    closingMessage: YildiznameNarrativeBlock(
      text: 'Yavaşça kendi ritmine dön.',
      factRefs: const [],
      themeRefs: const [],
    ),
  );
}

List<StarMapResultSection> sampleLegacySections() => const [
      StarMapResultSection(title: 'Gökyüzü', body: 'Bugün sakin bir nefes.'),
      StarMapResultSection(title: 'Anlam', body: 'İç sesini dinle.'),
    ];
