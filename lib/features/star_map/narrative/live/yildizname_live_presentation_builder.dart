/// Phase 8B — build live Narrative presentation from durable artifact.
library;

import '../../artifacts/yildizname_artifact.dart';
import '../../artifacts/yildizname_artifact_or_context.dart';
import '../../artifacts/yildizname_artifact_presentation.dart';
import '../../result/yildizname_continuity_presentation.dart';
import '../../result/yildizname_continuity_projector.dart';
import '../../result/yildizname_result_actions_builder.dart';
import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_narrative_structured_result.dart';

abstract final class YildiznameLivePresentationBuilder {
  YildiznameLivePresentationBuilder._();

  static YildiznameResultPresentation build({
    required YildiznameNarrativeRequest request,
    required YildiznameNarrativeStructuredResult result,
    required YildiznameArtifact artifact,
    required Iterable<YildiznameArtifact> history,
    required String chromeLocale,
  }) {
    final base = YildiznameArtifactPresentation.narrativeLive(
      request: request,
      result: result,
      artifactId: artifact.id,
      createdAtUtc: artifact.createdAtUtc,
      chromeLocale: chromeLocale,
    );
    YildiznameContinuityPresentation continuity;
    try {
      continuity = YildiznameContinuityProjector.project(
        current: artifact,
        history: history,
        languageCode: chromeLocale,
      );
    } catch (_) {
      continuity = YildiznameContinuityPresentation.empty;
    }
    final withContinuity = base.withContinuity(continuity);
    return withContinuity.withActions(
      YildiznameResultActionsBuilder.build(
        presentation: withContinuity,
        orContext: YildiznameArtifactOrContext.build(artifact),
      ),
    );
  }
}
