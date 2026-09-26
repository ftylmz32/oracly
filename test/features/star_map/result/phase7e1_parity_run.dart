/// Phase 7E.1 — narrative live/reopen parity runner.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions_builder.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_types.dart';

import '../../../support/yildizname_result_fixtures.dart';
import 'phase7e1_parity_assert.dart';

void phase7e1RunNarrativeParity({
  required YildiznameNarrativeScope scope,
  required bool rich,
  required String resultLocale,
  required String chromeLocale,
  required String artifactId,
  bool assertStoredProseUntranslated = false,
}) {
  final request = yildiznameFixtureRequest(
    scope: scope,
    rich: rich,
    languageCode: resultLocale,
  );
  final result = yildiznameFixtureResult(
    scope: scope,
    languageCode: resultLocale,
    kinds: scope == YildiznameNarrativeScope.full
        ? const [
            YildiznameSectionKind.coreIdentity,
            YildiznameSectionKind.emotionalWorld,
            YildiznameSectionKind.anglesAndHouses,
          ]
        : const [YildiznameSectionKind.coreIdentity],
    summary: 'Güneş Leo konumunda sabırlı bir odak taşır.',
  );
  final artifact = YildiznameArtifactFactory.createNarrative(
    ownerId: 'parity-owner',
    request: request,
    result: result,
    semanticFingerprint: 'sem-parity-7e1',
    evidenceFingerprint: 'ev-parity-7e1',
    createdAtUtc: DateTime.utc(2026, 4, 4, 12),
    id: artifactId,
  );

  final live = YildiznameArtifactPresentation.narrativeLive(
    request: request,
    result: result,
    artifactId: artifact.id,
    createdAtUtc: artifact.createdAtUtc,
    chromeLocale: chromeLocale,
  );
  final reopen = YildiznameArtifactPresentation.of(
    artifact,
    chromeLocale: chromeLocale,
  );

  expect(identical(live, reopen), isFalse);
  expect(live.source, YildiznameResultSource.narrativeLive);
  expect(reopen.source, YildiznameResultSource.narrativeArtifact);
  phase7e1AssertPresentationParity(live, reopen);

  if (assertStoredProseUntranslated) {
    final prose = live.sections.map((s) => s.body).join('|');
    expect(prose.contains('Güneş'), isTrue);
    expect(live.chromeLanguage, 'en');
    expect(reopen.chromeLanguage, 'en');
    expect(live.sections.map((s) => s.body), reopen.sections.map((s) => s.body));
  }

  if (scope == YildiznameNarrativeScope.full && rich) {
    expect(live.factSnapshot.isNotEmpty, isTrue);
    expect(reopen.factSnapshot.isNotEmpty, isTrue);
  }

  final or = YildiznameArtifactOrContext.build(artifact);
  final liveActions = YildiznameResultActionsBuilder.build(
    presentation: live,
    orContext: or,
  );
  final reopenActions = YildiznameResultActionsBuilder.build(
    presentation: reopen,
    orContext: or,
  );
  expect(identical(liveActions, reopenActions), isFalse);
  phase7e1AssertActionParity(liveActions, reopenActions);
}
