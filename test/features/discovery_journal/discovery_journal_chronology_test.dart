/// Chronology chapters from real dates only.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/discovery_journal/copy/discovery_journal_copy.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_entry.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_kind.dart';
import 'package:oracly_new/features/discovery_journal/presentation/widgets/discovery_journal_chronology.dart';

DiscoveryJournalEntry _e(DateTime date) => DiscoveryJournalEntry(
      id: date.toIso8601String(),
      kind: DiscoveryJournalKind.tarot,
      date: date,
      title: 't',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('groups by recency without inventing rows', () {
    final now = DateTime(2026, 8, 23);
    final chapters = DiscoveryJournalChronology.chapters(
      [
        _e(DateTime(2026, 8, 22)),
        _e(DateTime(2026, 8, 10)),
        _e(DateTime(2026, 7, 1)),
      ],
      now: now,
    );
    expect(chapters, hasLength(3));
    expect(chapters[0].label, DiscoveryJournalCopy.recency('recent'));
    expect(chapters[1].label, DiscoveryJournalCopy.recency('aging'));
    expect(chapters[2].label, DiscoveryJournalCopy.recency('distant'));
    expect(chapters.map((c) => c.entries.length).toList(), [1, 1, 1]);
  });

  test('single band stays unlabeled to avoid fake chapters', () {
    final now = DateTime(2026, 8, 23);
    final chapters = DiscoveryJournalChronology.chapters(
      [_e(DateTime(2026, 8, 20)), _e(DateTime(2026, 8, 21))],
      now: now,
    );
    expect(chapters, hasLength(1));
    expect(chapters.single.label, isEmpty);
    expect(chapters.single.entries, hasLength(2));
  });
}
