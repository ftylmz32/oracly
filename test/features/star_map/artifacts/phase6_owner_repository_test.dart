/// C — Owner isolation for artifact repository.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_exceptions.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('C owner A artifacts invisible to B; B cannot delete/overwrite', () async {
    useFixedIds(const [
      'yid_cccccccccccccccccccccccccccccccc',
      'yid_dddddddddddddddddddddddddddddddd',
    ]);
    final storage = fakeLocalStorage();
    final repoA = artifactRepo(storage, 'ownerA');
    await repoA.saveNew(
      YildiznameArtifactFactory.createLegacy(
        ownerId: 'ownerA',
        title: 'A1',
        sections: sampleLegacySections(),
        sectionKind: YildiznameLegacySectionKind.skyMessage,
        locale: 'tr',
        dayKey: 'd1',
      ),
    );
    await repoA.saveNew(
      YildiznameArtifactFactory.createLegacy(
        ownerId: 'ownerA',
        title: 'A2',
        sections: sampleLegacySections(),
        sectionKind: YildiznameLegacySectionKind.innerArchive,
        locale: 'tr',
        dayKey: 'd2',
      ),
    );
    expect(await repoA.getAll(), hasLength(2));

    final repoB = artifactRepo(storage, 'ownerB');
    expect(await repoB.getAll(), isEmpty);
    expect(await repoB.getById('yid_cccccccccccccccccccccccccccccccc'), isNull);

    await repoB.delete('yid_cccccccccccccccccccccccccccccccc');
    expect(await repoA.getAll(), hasLength(2));

    final conflict = YildiznameArtifactFactory.createLegacy(
      ownerId: 'ownerB',
      title: 'hijack',
      sections: sampleLegacySections(),
      sectionKind: YildiznameLegacySectionKind.skyMessage,
      locale: 'en',
      dayKey: 'x',
      id: 'yid_cccccccccccccccccccccccccccccccc',
    );
    // Same id different content must not overwrite A.
    expect(
      () => repoB.saveNew(conflict),
      throwsA(isA<YildiznameArtifactDuplicateConflictException>()),
    );
    expect(await repoA.getById('yid_cccccccccccccccccccccccccccccccc'), isNotNull);

    expect(
      () => artifactRepo(storage, null).getAll(),
      throwsA(isA<YildiznameArtifactOwnerUnavailableException>()),
    );
    expect(storage.getStringList('yildizname_artifacts_v1'), isNotEmpty);
  });
}
