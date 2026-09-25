/// G — Memory support requires ≥2 artifacts; delete drops recurrence.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_memory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('G theme X support=2 then delete → not recurring', () async {
    useFixedIds(const [
      'yid_g1g1g1g1g1g1g1g1g1g1g1g1g1g1g1g1',
      'yid_g2g2g2g2g2g2g2g2g2g2g2g2g2g2g2g2',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final themes = const [
      YildiznameThemeFact(themeRef: 'theme.x', label: 'X'),
    ];
    await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: themes),
      result: sampleResult(themeRefs: const ['theme.x'], summary: 'Birinci X okuması burada.'),
      semanticFingerprint: 'g-sem-1',
    );
    final a2 = await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: themes),
      result: sampleResult(themeRefs: const ['theme.x'], summary: 'İkinci X okuması burada.'),
      semanticFingerprint: 'g-sem-2',
    );

    var recurring = YildiznameArtifactMemory.recurringThemes(await repo.getAll());
    expect(recurring.single.themeRef, 'theme.x');
    expect(recurring.single.supportCount, 2);

    await repo.delete(a2.id);
    recurring = YildiznameArtifactMemory.recurringThemes(await repo.getAll());
    expect(recurring, isEmpty);
  });
}
