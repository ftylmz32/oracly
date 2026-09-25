/// F — Delete removes artifact from history/memory; favorite snapshot remains.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/birth_chart_record.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moment_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_journal.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_memory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('F delete drops journal/memory source; favorite quote kept; birth stays',
      () async {
    useFixedIds(const [
      'yid_f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1',
      'yid_f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2',
    ]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final birth = LocalBirthChartRepository(storage, ownerId: 'o1');
    await birth.save(
      BirthChartRecord(
        id: 'birth-1',
        ownerId: 'o1',
        createdAt: DateTime.utc(2026, 1, 1),
        payload: const {'sunSign': 'leo'},
      ),
    );

    final service = YildiznameNarrativeCompletionService(repo);
    final themes = const [
      YildiznameThemeFact(themeRef: 'theme.x', label: 'X'),
    ];
    final a1 = await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: themes),
      result: sampleResult(themeRefs: const ['theme.x'], summary: 'Birinci metin sabır.'),
      semanticFingerprint: 'sem-a',
      createdAtUtc: DateTime.utc(2026, 1, 2),
    );
    final a2 = await service.complete(
      ownerId: 'o1',
      request: sampleRequest(themes: themes),
      result: sampleResult(themeRefs: const ['theme.x'], summary: 'İkinci metin sabır.'),
      semanticFingerprint: 'sem-b',
      createdAtUtc: DateTime.utc(2026, 1, 3),
    );
    final fav = FavoriteMomentFactory.starMapFromArtifact(a1);
    expect(YildiznameArtifactJournal.entry(a1).id, a1.id);
    expect(
      YildiznameArtifactMemory.recurringThemes(await repo.getAll()),
      isNotEmpty,
    );

    await repo.delete(a1.id);
    expect(await repo.getById(a1.id), isNull);
    expect(await repo.getById(a2.id), isNotNull);
    expect(fav.quote, isNotEmpty);
    expect(await birth.getLatest(), isNotNull);
  });
}
