/// D — FavoriteMomentFactory.starMapArtifact durable identity.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moment_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_id.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_reopen.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('D favorite uses yid — no Object.hash', () async {
    const id = 'yid_abcabcabcabcabcabcabcabcabcabcab';
    useFixedIds(const [id]);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final artifact = await repo.saveNew(
      YildiznameArtifactFactory.createLegacy(
        ownerId: 'o1',
        title: 'Başlık',
        sections: sampleLegacySections(),
        sectionKind: YildiznameLegacySectionKind.skyMessage,
        locale: 'tr',
        dayKey: '2026-01-11',
        id: id,
      ),
    );
    final fav = FavoriteMomentFactory.starMapFromArtifact(artifact);
    expect(fav.id, 'starMap:$id');
    expect(fav.sourceRef, id);
    expect(YildiznameArtifactId.isValid(fav.sourceRef), isTrue);
    expect(fav.id.contains('Object.hash'), isFalse);

    final reopened = await YildiznameArtifactReopen(repo).requireById(fav.sourceRef);
    expect(reopened.id, artifact.id);
    expect(reopened.contentHash, artifact.contentHash);
  });
}
