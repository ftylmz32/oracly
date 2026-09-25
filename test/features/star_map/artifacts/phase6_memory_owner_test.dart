/// Memory owner isolation A↛B.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_memory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('owner B memory sees 0 of A themes', () async {
    useFixedIds(const [
      'yid_m1m1m1m1m1m1m1m1m1m1m1m1m1m1m1m1',
      'yid_m2m2m2m2m2m2m2m2m2m2m2m2m2m2m2m2',
    ]);
    final storage = fakeLocalStorage();
    final themes = const [
      YildiznameThemeFact(themeRef: 'theme.x', label: 'X'),
    ];
    final serviceA = YildiznameNarrativeCompletionService(artifactRepo(storage, 'A'));
    for (final sem in ['a1', 'a2']) {
      await serviceA.complete(
        ownerId: 'A',
        request: sampleRequest(themes: themes),
        result: sampleResult(themeRefs: const ['theme.x'], summary: 'A $sem metni.'),
        semanticFingerprint: sem,
      );
    }
    final bAll = await artifactRepo(storage, 'B').getAll();
    expect(bAll, isEmpty);
    expect(YildiznameArtifactMemory.recurringThemes(bAll), isEmpty);
  });
}
