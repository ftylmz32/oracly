/// H — Request theme unused by accepted result must not count.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_memory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('H available-but-unused theme X is not historical', () async {
    useFixedIds(const [
      'yid_h1h1h1h1h1h1h1h1h1h1h1h1h1h1h1h1',
      'yid_h2h2h2h2h2h2h2h2h2h2h2h2h2h2h2h2',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final themes = const [
      YildiznameThemeFact(themeRef: 'theme.x', label: 'X'),
      YildiznameThemeFact(themeRef: 'theme.y', label: 'Y'),
    ];
    for (final sem in ['h-1', 'h-2']) {
      await service.complete(
        ownerId: 'o1',
        request: sampleRequest(themes: themes),
        result: sampleResult(
          themeRefs: const ['theme.y'],
          summary: 'Y teması görünen kabul edilmiş metin $sem.',
        ),
        semanticFingerprint: sem,
      );
    }
    final recurring =
        YildiznameArtifactMemory.recurringThemes(await repo.getAll());
    expect(recurring.map((e) => e.themeRef), isNot(contains('theme.x')));
    expect(recurring.single.themeRef, 'theme.y');
  });
}
