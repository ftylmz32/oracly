/// Phase 7G — live/artifact parity fixture (test-only).
library;

import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_actions_builder.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_presentation.dart';

import '../../support/yildizname_result_fixtures.dart';
import 'yildizname_phase7g_fixtures.dart';

({YildiznameArtifact artifact, YildiznameResultPresentation live})
    phase7gLiveAndArtifact({String chromeLocale = 'tr'}) {
  final request = yildiznameFixtureRequest(
    scope: YildiznameNarrativeScope.full,
    rich: true,
    languageCode: 'tr',
  );
  final result = yildiznameFixtureResult(
    scope: YildiznameNarrativeScope.full,
    kinds: phase7gFullKinds,
    languageCode: 'tr',
    summary: 'Güneş, Ay ve Yükselen birlikte sabırlı bir kimlik ekseni kurar.',
    sectionTexts: const [
      'Doğum göğünde kimlik net ve sakin duruyor.',
      'Duygusal dünya yumuşak bir ritme çağırıyor.',
      'Açılar ve evler derinleşmeyi destekliyor.',
    ],
    reflection: 'Hangi katman sana en dürüst geliyor?',
    closing: 'Arşiv kapanır; sen kendi ritmine dönersin.',
  );
  const id = 'yid_7gliveeq7gliveeq7gliveeq7gliv00';
  final at = DateTime.utc(2026, 7, 3);
  final artifact = YildiznameArtifactFactory.createNarrative(
    ownerId: 'visual-7g',
    request: request,
    result: result,
    semanticFingerprint: 'sem-7g-parity',
    evidenceFingerprint: 'ev-7g-parity',
    createdAtUtc: at,
    id: id,
  );
  var live = YildiznameArtifactPresentation.narrativeLive(
    request: request,
    result: result,
    artifactId: id,
    createdAtUtc: at,
    chromeLocale: chromeLocale,
  );
  final or = YildiznameArtifactOrContext.build(artifact);
  live = live.withActions(
    YildiznameResultActionsBuilder.build(presentation: live, orContext: or),
  );
  return (artifact: artifact, live: live);
}
