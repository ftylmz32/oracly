/// A — Narrative exact reopen after environment mutation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_reopen.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_payload.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('A narrative exact reopen — 0 provider, prose+facts preserved', () async {
    useFixedIds(const ['yid_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa']);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'ownerA');
    final service = YildiznameNarrativeCompletionService(repo);
    final request = sampleRequest(
      themes: const [
        YildiznameThemeFact(themeRef: 'theme.patience', label: 'sabır'),
      ],
    );
    final result = sampleResult(themeRefs: const ['theme.patience']);
    final saved = await service.complete(
      ownerId: 'ownerA',
      request: request,
      result: result,
      semanticFingerprint: 'yildizname_narrative_v1_sem1',
      evidenceFingerprint: 'ev-1',
      createdAtUtc: DateTime.utc(2026, 1, 10),
    );

    // Mutate environment (storage/repo reconstructed; locale/day/flag irrelevant).
    final repo2 = artifactRepo(storage, 'ownerA');
    final reopen = YildiznameArtifactReopen(repo2);
    final loaded = await reopen.requireById(saved.id);

    expect(loaded.resultLocale, 'tr');
    expect(loaded.payload['request'], request.toProviderJson());
    expect(
      YildiznameNarrativePayload.resultOf(loaded.payload)!['summary']['text'],
      result.summary.text,
    );
    final presentation = YildiznameArtifactPresentation.of(loaded);
    expect(presentation.sections.any((s) => s.body.contains('Leo')), isTrue);
    expect(
      presentation.sections.any((s) => s.body.contains('place.sun.leo')),
      isFalse,
    );
    expect(identical(repo2, repo), isFalse);
  });
}
