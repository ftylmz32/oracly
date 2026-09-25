/// Phase 6 — favorite / journal open paths (exact vs legacy hub).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moment_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_id.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_reopen.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('exact favorite sourceRef reopens stored artifact', () async {
    const id = 'yid_33333333333333333333333333333333';
    useFixedIds(const [id]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final artifact = await repo.saveNew(
      YildiznameArtifactFactory.createLegacy(
        ownerId: 'o1',
        title: 'Gökyüzü',
        sections: sampleLegacySections(),
        sectionKind: YildiznameLegacySectionKind.skyMessage,
        locale: 'tr',
        dayKey: '2026-01-13',
        id: id,
      ),
    );
    final fav = FavoriteMomentFactory.starMapArtifact(
      artifactId: artifact.id,
      at: artifact.createdAtUtc,
      title: 'Gökyüzü',
      insight: 'Bugün sakin bir nefes.',
    );
    expect(YildiznameArtifactId.isValid(fav.sourceRef), isTrue);
    final loaded =
        await YildiznameArtifactReopen(repo).requireById(fav.sourceRef);
    expect(loaded.id, artifact.id);
    expect(loaded.contentHash, artifact.contentHash);
  });

  test('missing yid favorite does not invent an artifact', () async {
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    const missing = 'yid_44444444444444444444444444444444';
    expect(YildiznameArtifactId.isValid(missing), isTrue);
    final loaded = await YildiznameArtifactReopen(repo).byId(missing);
    expect(loaded, isNull);
    final fav = FavoriteMoment(
      id: 'starMap:$missing',
      source: FavoriteMomentSource.starMap,
      sourceRef: missing,
      savedAt: DateTime.utc(2026, 1, 1),
      occurredAt: DateTime.utc(2026, 1, 1),
      quote: 'Kayıp anı',
    );
    expect(fav.sourceRef, missing);
  });

  test('legacy hash favorite stays non-artifact compatible', () {
    final fav = FavoriteMomentFactory.starMap(
      ref: 'star-999',
      at: DateTime.utc(2026, 1, 1),
      title: 'Eski',
      insight: 'Eski',
    );
    expect(YildiznameArtifactId.isValid(fav.sourceRef), isFalse);
  });
}
