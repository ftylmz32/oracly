/// OR privacy — no birth/owner/fingerprint/machine refs in OR text.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_or_context.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('OR context excludes birth/owner/fingerprints/factRefs', () async {
    useFixedIds(const ['yid_oooooooooooooooooooooooooooooooo']);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'secret-owner');
    final artifact = await YildiznameNarrativeCompletionService(repo).complete(
      ownerId: 'secret-owner',
      request: sampleRequest(
        themes: const [
          YildiznameThemeFact(themeRef: 'theme.x', label: 'X'),
        ],
      ),
      result: sampleResult(themeRefs: const ['theme.x']),
      semanticFingerprint: 'sem-secret',
      evidenceFingerprint: 'ev-secret',
    );
    final ctx = YildiznameArtifactOrContext.build(artifact);
    final blob = [
      ctx.sessionId,
      ctx.interpretationSummary,
      ctx.fullInterpretation ?? '',
      ctx.cardsSummary,
      ctx.sourceLabel,
    ].join('\n');
    expect(blob.contains('secret-owner'), isFalse);
    expect(blob.contains('ev-secret'), isFalse);
    expect(blob.contains('sem-secret'), isFalse);
    expect(blob.contains('place.sun.leo'), isFalse);
    expect(YildiznameArtifactOrContext.containsForbidden(blob), isFalse);
    expect(ctx.sessionId, artifact.id);
  });
}
