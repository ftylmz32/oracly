/// L — UserLocalDataWipe clears yildizname_artifacts_v1.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('L account wipe clears artifact key truthfully', () async {
    useFixedIds(const ['yid_llllllllllllllllllllllllllllllll']);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    await repo.saveNew(
      YildiznameArtifactFactory.createLegacy(
        ownerId: 'o1',
        title: 'Wipe me',
        sections: sampleLegacySections(),
        sectionKind: YildiznameLegacySectionKind.planetCatalogue,
        locale: 'tr',
        dayKey: 'd1',
      ),
    );
    expect(
      storage.getStringList(LocalYildiznameArtifactRepository.storageKey),
      isNotEmpty,
    );

    final result = await UserLocalDataWipe.run(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    expect(
      result.failedOperations,
      isNot(contains('yildizname_artifacts_v1')),
    );
    expect(
      storage.getStringList(LocalYildiznameArtifactRepository.storageKey),
      isNull,
    );
  });
}
