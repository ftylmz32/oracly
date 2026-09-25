/// Phase 6 wiring — Object.hash gone; durable favorites + journal fallback.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/birth_chart_record.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_kind.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_aggregator.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_map.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moment_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_id.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('result screen source has no Object.hash favorite mint', () {
    final file = File(
      'lib/features/star_map/presentation/reference/'
      'star_map_reference_result_screen.dart',
    );
    final src = file.readAsStringSync();
    expect(src.contains('Object.hash'), isFalse);
    expect(src.contains('artifactId'), isTrue);
  });

  test('favorite id is starMap:yid_…', () {
    const id = 'yid_ffffffffffffffffffffffffffffffff';
    final fav = FavoriteMomentFactory.starMapArtifact(
      artifactId: id,
      at: DateTime.utc(2026, 1, 12),
      title: 'Gökyüzü',
      insight: 'Sakin bir bakış.',
    );
    expect(fav.id, 'starMap:$id');
    expect(fav.sourceRef, id);
    expect(fav.source, FavoriteMomentSource.starMap);
    expect(YildiznameArtifactId.isValid(fav.sourceRef), isTrue);
  });

  test('old star-<hash> favorite is not a valid artifact id', () {
    final legacy = FavoriteMomentFactory.starMap(
      ref: 'star-12345',
      at: DateTime.utc(2026, 1, 1),
      title: 'Eski',
      insight: 'Eski alıntı',
    );
    expect(YildiznameArtifactId.isValid(legacy.sourceRef), isFalse);
    expect(legacy.id, 'starMap:star-12345');
  });

  test('journal uses artifacts and skips BirthChartRecord duplicate', () {
    useFixedIds(const ['yid_11111111111111111111111111111111']);
    final artifact = YildiznameArtifactFactory.createLegacy(
      ownerId: 'o1',
      title: 'Arşiv',
      sections: sampleLegacySections(),
      sectionKind: YildiznameLegacySectionKind.skyMessage,
      locale: 'tr',
      dayKey: '2026-01-12',
    );
    final chart = BirthChartRecord(
      id: 'chart-1',
      createdAt: DateTime(2026, 1, 1),
      payload: const {},
    );
    final withArtifacts = DiscoveryJournalAggregator.merge(
      starChart: chart,
      starMapArtifacts: [artifact],
    );
    expect(withArtifacts, hasLength(1));
    expect(withArtifacts.single.id, artifact.id);
    expect(withArtifacts.single.kind, DiscoveryJournalKind.starMap);

    final fallback = DiscoveryJournalAggregator.merge(starChart: chart);
    expect(fallback, hasLength(1));
    expect(fallback.single.id, 'chart-1');
  });

  test('DiscoveryJournalMap.starMapArtifact delegates to artifact id', () {
    useFixedIds(const ['yid_22222222222222222222222222222222']);
    final artifact = YildiznameArtifactFactory.createLegacy(
      ownerId: 'o1',
      title: 'Başlık',
      sections: sampleLegacySections(),
      sectionKind: YildiznameLegacySectionKind.innerArchive,
      locale: 'tr',
    );
    final entry = DiscoveryJournalMap.starMapArtifact(artifact);
    expect(entry.id, artifact.id);
    expect(entry.kind, DiscoveryJournalKind.starMap);
  });
}
