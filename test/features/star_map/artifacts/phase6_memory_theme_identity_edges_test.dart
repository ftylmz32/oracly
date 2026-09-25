/// Phase 6.1 — theme identity edges (legacy, normalize, order).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_memory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_source.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_capture_service.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_theme_identity.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('I legacyLocal excluded from recurring themes', () async {
    useFixedIds(const [
      'yid_l1l1l1l1l1l1l1l1l1l1l1l1l1l1l1l1',
      'yid_l2l2l2l2l2l2l2l2l2l2l2l2l2l2l2l2',
      'yid_l3l3l3l3l3l3l3l3l3l3l3l3l3l3l3l3',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final capture = YildiznameLegacyCaptureService(repo);
    await capture.captureLeaf(
      ownerId: 'o1',
      title: 'Gökyüzü',
      sections: sampleLegacySections(),
      sectionKind: YildiznameLegacySectionKind.skyMessage,
      locale: 'tr',
      planets: const [],
      sunSignId: 'leo',
      dayKey: '2026-01-10',
    );
    final service = YildiznameNarrativeCompletionService(repo);
    for (final sem in ['rt-leg-1', 'rt-leg-2']) {
      await service.complete(
        ownerId: 'o1',
        request: sampleRequest(themes: const [
          YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır'),
        ]),
        result:
            sampleResult(themeRefs: const ['theme.0'], summary: 'Sabır $sem'),
        semanticFingerprint: sem,
      );
    }
    final all = await repo.getAll();
    expect(all.where((a) => a.source == YildiznameArtifactSource.legacyLocal),
        isNotEmpty);
    final recurring = YildiznameArtifactMemory.recurringThemes(all);
    expect(recurring.single.supportCount, 2);
    expect(recurring.single.label, 'Sabır');
  });

  test('normalize case/whitespace — no synonym merge', () {
    expect(YildiznameThemeIdentity.sameLabel('Sabır', ' sabır '), isTrue);
    expect(YildiznameThemeIdentity.sameLabel('Patience', 'PATIENCE'), isTrue);
    expect(YildiznameThemeIdentity.sameLabel('Sabır', 'Kariyer'), isFalse);
    expect(YildiznameThemeIdentity.sameLabel('öz güven', 'kendine güven'),
        isFalse);
    // ASCII SABIR vs Turkish Sabır (ı) may stay distinct — FN preferred.
    expect(YildiznameThemeIdentity.sameLabel('Sabır', 'SABIR'), isFalse);
    expect(
      YildiznameThemeIdentity.keyFor('Sabır'),
      YildiznameThemeIdentity.keyFor('  sabır  '),
    );
  });

  test('K L deterministic order and reorder invariance', () async {
    useFixedIds(const [
      'yid_k1k1k1k1k1k1k1k1k1k1k1k1k1k1k1k1',
      'yid_k2k2k2k2k2k2k2k2k2k2k2k2k2k2k2k2',
      'yid_k3k3k3k3k3k3k3k3k3k3k3k3k3k3k3k3',
      'yid_k4k4k4k4k4k4k4k4k4k4k4k4k4k4k4k4',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final service = YildiznameNarrativeCompletionService(repo);
    Future<void> save(String label, String sem) async {
      await service.complete(
        ownerId: 'o1',
        request: sampleRequest(themes: [
          YildiznameThemeFact(themeRef: 'theme.0', label: label),
        ]),
        result:
            sampleResult(themeRefs: const ['theme.0'], summary: '$label $sem'),
        semanticFingerprint: sem,
      );
    }

    await save('Alpha', 'rt-k1');
    await save('Alpha', 'rt-k2');
    await save('Beta', 'rt-k3');
    await save('Beta', 'rt-k4');

    final all = await repo.getAll();
    final forward = YildiznameArtifactMemory.recurringThemes(all);
    final reversed = YildiznameArtifactMemory.recurringThemes(all.reversed);
    expect(forward.map((e) => e.themeKey).toList(),
        reversed.map((e) => e.themeKey).toList());
    expect(forward, hasLength(2));
  });
}
