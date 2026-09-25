/// E — Journal entry maps to artifact id; reopen exact.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_kind.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_journal.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_reopen.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('E journal entry is starMap with artifact id — exact reopen', () async {
    useFixedIds(const ['yid_eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee']);
    final storage = fakeLocalStorage();
    final repo = artifactRepo(storage, 'o1');
    final artifact = await repo.saveNew(
      YildiznameArtifactFactory.createLegacy(
        ownerId: 'o1',
        title: 'Arşiv',
        sections: sampleLegacySections(),
        sectionKind: YildiznameLegacySectionKind.innerArchive,
        locale: 'tr',
        dayKey: 'd1',
      ),
    );
    final entry = YildiznameArtifactJournal.entry(artifact);
    expect(entry.kind, DiscoveryJournalKind.starMap);
    expect(entry.id, artifact.id);

    final loaded =
        await YildiznameArtifactReopen(repo).requireById(entry.id);
    expect(loaded.contentHash, artifact.contentHash);
  });
}
