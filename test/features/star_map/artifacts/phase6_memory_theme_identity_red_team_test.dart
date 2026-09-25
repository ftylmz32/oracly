/// Phase 6.1 — core theme identity red-team (positional ref ≠ identity).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_memory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_theme_identity.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('A same theme.0 different labels → NOT recurring', () async {
    useFixedIds(const [
      'yid_a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1',
      'yid_a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: const [
        YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır'),
      ]),
      result: sampleResult(themeRefs: const ['theme.0'], summary: 'A sabır okuması.'),
      semanticFingerprint: 'rt-a1',
    );
    await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: const [
        YildiznameThemeFact(themeRef: 'theme.0', label: 'Kariyer'),
      ]),
      result: sampleResult(themeRefs: const ['theme.0'], summary: 'B kariyer okuması.'),
      semanticFingerprint: 'rt-a2',
    );
    final recurring =
        YildiznameArtifactMemory.recurringThemes(await repo.getAll());
    expect(recurring, isEmpty,
        reason: 'positional theme.0 must not merge Sabır+Kariyer');
  });

  test('B different refs same label → recurring Sabır support=2', () async {
    useFixedIds(const [
      'yid_b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1',
      'yid_b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    final a = await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: const [
        YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır'),
      ]),
      result: sampleResult(themeRefs: const ['theme.0'], summary: 'A sabır.'),
      semanticFingerprint: 'rt-b1',
    );
    final b = await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: const [
        YildiznameThemeFact(themeRef: 'theme.2', label: 'Sabır'),
      ]),
      result: sampleResult(themeRefs: const ['theme.2'], summary: 'B sabır.'),
      semanticFingerprint: 'rt-b2',
    );
    final recurring =
        YildiznameArtifactMemory.recurringThemes(await repo.getAll());
    expect(recurring, hasLength(1));
    expect(recurring.single.label, 'Sabır');
    expect(recurring.single.supportCount, 2);
    expect(recurring.single.sourceArtifactIds, containsAll([a.id, b.id]));
    expect(recurring.single.themeKey, YildiznameThemeIdentity.keyFor('Sabır'));
    expect(recurring.single.themeKey.startsWith('yth_'), isTrue);
  });

  test('C same artifact duplicate equivalent labels → one support', () async {
    useFixedIds(const [
      'yid_c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1',
      'yid_c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: const [
        YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır'),
        YildiznameThemeFact(themeRef: 'theme.1', label: ' sabır '),
        YildiznameThemeFact(themeRef: 'theme.2', label: '  Sabır  '),
      ]),
      result: sampleResult(
        themeRefs: const ['theme.0', 'theme.1', 'theme.2'],
        summary: 'Tek artifact çok sabır.',
      ),
      semanticFingerprint: 'rt-c1',
    );
    await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: const [
        YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır'),
      ]),
      result: sampleResult(themeRefs: const ['theme.0'], summary: 'İkinci sabır.'),
      semanticFingerprint: 'rt-c2',
    );
    final recurring =
        YildiznameArtifactMemory.recurringThemes(await repo.getAll());
    expect(recurring.single.supportCount, 2);
  });

  test('E unused; F unknown accepted ref → no support', () async {
    useFixedIds(const [
      'yid_e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1',
      'yid_e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: const [
        YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır'),
        YildiznameThemeFact(themeRef: 'theme.1', label: 'Kariyer'),
      ]),
      result: sampleResult(themeRefs: const ['theme.0'], summary: 'Sadece sabır.'),
      semanticFingerprint: 'rt-e1',
    );
    await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: const [
        YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır'),
      ]),
      result: sampleResult(themeRefs: const ['theme.9'], summary: 'Bilinmeyen ref.'),
      semanticFingerprint: 'rt-e2',
    );
    final recurring =
        YildiznameArtifactMemory.recurringThemes(await repo.getAll());
    expect(recurring, isEmpty);
  });
}
