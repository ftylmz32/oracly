/// I — Current semantic fingerprint excluded from prior memory.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_memory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('I exclude current semanticFingerprint — no self recursion', () async {
    useFixedIds(const [
      'yid_i1i1i1i1i1i1i1i1i1i1i1i1i1i1i1i1',
      'yid_i2i2i2i2i2i2i2i2i2i2i2i2i2i2i2i2',
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
      result: sampleResult(themeRefs: const ['theme.x'], summary: 'Önceki X metni.'),
      semanticFingerprint: 'prior-sem',
    );
    await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: themes),
      result: sampleResult(themeRefs: const ['theme.x'], summary: 'Şimdiki X metni.'),
      semanticFingerprint: 'current-sem',
    );

    final withSelf = YildiznameArtifactMemory.recurringThemes(await repo.getAll());
    expect(withSelf.single.supportCount, 2);

    final withoutSelf = YildiznameArtifactMemory.recurringThemes(
      await repo.getAll(),
      excludeSemanticFingerprint: 'current-sem',
    );
    expect(withoutSelf, isEmpty);
  });
}
