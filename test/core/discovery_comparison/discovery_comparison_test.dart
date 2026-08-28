/// Discovery comparison — engine gates and honest narrative.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/discovery_comparison/copy/discovery_comparison_copy.dart';
import 'package:oracly_new/core/discovery_comparison/models/discovery_comparison_kind.dart';
import 'package:oracly_new/core/discovery_comparison/models/discovery_comparison_snapshot.dart';
import 'package:oracly_new/core/discovery_comparison/services/discovery_comparison_engine.dart';
import 'package:oracly_new/core/discovery_comparison/services/discovery_comparison_pair_finder.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_entry.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_kind.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('labels match product copy', () {
    expect(DiscoveryComparisonCopy.before, 'ÖNCE');
    expect(DiscoveryComparisonCopy.now, 'ŞİMDİ');
    expect(DiscoveryComparisonCopy.obstacleToDirectionTarot, contains('engel'));
    expect(DiscoveryComparisonCopy.obstacleToDirectionTarot, isNot(contains('iyileş')));
  });

  test('tarot obstacle to direction synthesis is supported', () {
    final result = DiscoveryComparisonEngine.compare(
      kind: DiscoveryComparisonKind.tarot,
      earlier: _snap(
        id: 'a',
        date: DateTime(2026, 8, 1),
        text: 'Bu açılımda belirsizlik ve sınır konusu öne çıkıyor.',
      ),
      later: _snap(
        id: 'b',
        date: DateTime(2026, 8, 10),
        text: 'Yön değiştirme ve cesur bir karar alma alanı açılıyor.',
      ),
    );
    expect(result, isNotNull);
    expect(result!.synthesis, DiscoveryComparisonCopy.obstacleToDirectionTarot);
  });

  test('returns null without theme signal', () {
    expect(
      DiscoveryComparisonEngine.compare(
        kind: DiscoveryComparisonKind.dailyMessage,
        earlier: _snap(
          id: 'a',
          date: DateTime(2026, 8, 1),
          text: 'Sakin bir gün.',
        ),
        later: _snap(
          id: 'b',
          date: DateTime(2026, 8, 2),
          text: 'Nefes al.',
        ),
      ),
      isNull,
    );
  });

  test('pair finder selects nearest prior same kind', () {
    final items = [
      DiscoveryJournalEntry(
        id: 't2',
        kind: DiscoveryJournalKind.tarot,
        date: DateTime(2026, 8, 12),
        title: 'Son',
      ),
      DiscoveryJournalEntry(
        id: 't1',
        kind: DiscoveryJournalKind.tarot,
        date: DateTime(2026, 8, 5),
        title: 'Önceki',
      ),
      DiscoveryJournalEntry(
        id: 'd1',
        kind: DiscoveryJournalKind.dream,
        date: DateTime(2026, 8, 1),
        title: 'Rüya',
      ),
    ];
    final prior = DiscoveryComparisonPairFinder.priorEntry(items, items.first);
    expect(prior?.id, 't1');
  });
}

DiscoveryComparisonSnapshot _snap({
  required String id,
  required DateTime date,
  required String text,
}) {
  return DiscoveryComparisonSnapshot(
    id: id,
    date: date,
    title: 'Başlık',
    preview: text,
    text: text,
  );
}
