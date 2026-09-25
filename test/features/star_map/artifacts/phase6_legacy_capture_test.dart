/// B — Legacy exact reopen after day/locale change.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_reopen.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_capture_service.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';
import 'package:oracly_new/features/star_map/models/star_map_reading.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('B legacy exact reopen — no StarMapReadingService regeneration', () async {
    useFixedIds(const ['yid_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb']);
    final storage = fakeLocalStorage();
    final capture = YildiznameLegacyCaptureService(artifactRepo(storage, 'o1'));
    final planets = [
      const StarMapPlanetInfluence(
        nameTr: 'Güneş',
        influence: 'odak',
        explanation: 'sabit açıklama',
        polarity: StarMapPolarity.balanced,
      ),
    ];
    final saved = await capture.captureLeaf(
      ownerId: 'o1',
      title: 'Gökyüzü Mesajı',
      sections: sampleLegacySections(),
      sectionKind: YildiznameLegacySectionKind.skyMessage,
      locale: 'tr',
      planets: planets,
      sunSignId: 'leo',
      dayKey: '2026-01-10',
      createdAtUtc: DateTime.utc(2026, 1, 10),
    );
    expect(saved, isNotNull);

    final reopen = YildiznameArtifactReopen(artifactRepo(storage, 'o1'));
    final loaded = await reopen.requireById(saved!.id);
    final p = YildiznameArtifactPresentation.of(loaded);
    expect(p.title, 'Gökyüzü Mesajı');
    expect(p.sections.first.body, 'Bugün sakin bir nefes.');
    expect(p.planets.single.nameTr, 'Güneş');
    expect(loaded.resultLocale, 'tr');
  });
}
