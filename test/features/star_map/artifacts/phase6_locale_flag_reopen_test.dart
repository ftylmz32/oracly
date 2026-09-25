/// Locale/flag reopen — stored locale prose unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_reopen.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('locale/flag mutation does not rewrite stored TR prose', () async {
    useFixedIds(const ['yid_pppppppppppppppppppppppppppppppp']);
    final storage = fakeLocalStorage();
    final saved = await YildiznameNarrativeCompletionService(
      artifactRepo(storage, 'o1'),
    ).complete(
      ownerId: 'o1',
      request: sampleRequest(),
      result: sampleResult(summary: 'Türkçe saklı özet metni sabittir.'),
      semanticFingerprint: 'locale-sem',
      createdAtUtc: DateTime.utc(2026, 1, 1),
    );

    // Fresh repo — simulates app restart + locale EN / flag false.
    final loaded =
        await YildiznameArtifactReopen(artifactRepo(storage, 'o1')).requireById(saved.id);
    expect(loaded.resultLocale, 'tr');
    final body = YildiznameArtifactPresentation.of(loaded).sections.first.body;
    expect(body, contains('Türkçe'));
    expect(body.toLowerCase(), isNot(contains('english')));
  });
}
