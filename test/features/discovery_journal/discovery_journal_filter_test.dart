/// Advanced discovery journal filters — local only, never AI.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_entry.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_kind.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_query.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_range.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_filter_engine.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_saved.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';

DiscoveryJournalEntry _entry({
  required String id,
  required DiscoveryJournalKind kind,
  required DateTime date,
  List<String> themes = const [],
  bool isSaved = false,
}) {
  return DiscoveryJournalEntry(
    id: id,
    kind: kind,
    date: date,
    title: id,
    themes: themes,
    isSaved: isSaved,
  );
}

void main() {
  final now = DateTime(2026, 8, 20, 12);

  final items = [
    _entry(
      id: 'recent-tarot',
      kind: DiscoveryJournalKind.tarot,
      date: DateTime(2026, 8, 18),
      themes: const ['değişim'],
      isSaved: true,
    ),
    _entry(
      id: 'mid-coffee',
      kind: DiscoveryJournalKind.coffee,
      date: DateTime(2026, 7, 10),
      themes: const ['iletişim'],
    ),
    _entry(
      id: 'old-dream',
      kind: DiscoveryJournalKind.dream,
      date: DateTime(2026, 4, 1),
      themes: const ['değişim', 'dinlenme'],
    ),
  ];

  test('date ranges only appear when they change the result set', () {
    final options = DiscoveryJournalFilterEngine.options(items, now: now);
    expect(options.ranges, [
      DiscoveryJournalRange.last7,
      DiscoveryJournalRange.last30,
      DiscoveryJournalRange.last90,
      DiscoveryJournalRange.all,
    ]);
    expect(
      DiscoveryJournalFilterEngine.options(
        [
          _entry(
            id: 'a',
            kind: DiscoveryJournalKind.tarot,
            date: DateTime(2026, 8, 19),
          ),
          _entry(
            id: 'b',
            kind: DiscoveryJournalKind.tarot,
            date: DateTime(2026, 8, 18),
          ),
        ],
        now: now,
      ).ranges,
      [DiscoveryJournalRange.all],
    );
  });

  test('feature and theme chips stay data-backed', () {
    final options = DiscoveryJournalFilterEngine.options(items, now: now);
    expect(options.kinds, [
      DiscoveryJournalKind.tarot,
      DiscoveryJournalKind.coffee,
      DiscoveryJournalKind.dream,
    ]);
    expect(options.themes, containsAll(['değişim', 'iletişim', 'dinlenme']));
    expect(options.hasSaved, isTrue);
  });

  test('saved filter hides unless real saved rows exist', () {
    final plain = [
      _entry(
        id: 'x',
        kind: DiscoveryJournalKind.tarot,
        date: DateTime(2026, 8, 1),
      ),
    ];
    expect(
      DiscoveryJournalFilterEngine.options(plain, now: now).hasSaved,
      isFalse,
    );
  });

  test('apply filters locally without inventing rows', () {
    final filtered = DiscoveryJournalFilterEngine.apply(
      items,
      const DiscoveryJournalQuery(
        range: DiscoveryJournalRange.last90,
        kind: DiscoveryJournalKind.tarot,
        savedOnly: true,
        theme: 'değişim',
      ),
      now: now,
    );
    expect(filtered.map((e) => e.id), ['recent-tarot']);
  });

  test('favorite moments mark matching journal ids as saved', () {
    final marked = DiscoveryJournalSaved.mark(
      [
        _entry(
          id: 'c1',
          kind: DiscoveryJournalKind.coffee,
          date: DateTime(2026, 8, 1),
        ),
      ],
      [
        FavoriteMoment(
          id: 'coffee:c1',
          source: FavoriteMomentSource.coffee,
          sourceRef: 'c1',
          savedAt: DateTime(2026, 8, 1),
          occurredAt: DateTime(2026, 8, 1),
          quote: 'Quiet',
        ),
      ],
    );
    expect(marked.single.isSaved, isTrue);
  });

  test('daily favorite dateKey marks daily_ prefix journal row saved', () {
    final marked = DiscoveryJournalSaved.mark(
      [
        _entry(
          id: 'daily_2026-08-10',
          kind: DiscoveryJournalKind.dailyMessage,
          date: DateTime(2026, 8, 10),
        ),
      ],
      [
        FavoriteMoment(
          id: 'dailyMessage:2026-08-10',
          source: FavoriteMomentSource.dailyMessage,
          sourceRef: '2026-08-10',
          savedAt: DateTime(2026, 8, 10),
          occurredAt: DateTime(2026, 8, 10),
          quote: 'Nefes',
        ),
      ],
    );
    expect(marked.single.isSaved, isTrue);
  });

  test('90-day window keeps mid-range and drops older', () {
    final week = DiscoveryJournalFilterEngine.apply(
      items,
      const DiscoveryJournalQuery(range: DiscoveryJournalRange.last7),
      now: now,
    );
    final ninety = DiscoveryJournalFilterEngine.apply(
      items,
      const DiscoveryJournalQuery(range: DiscoveryJournalRange.last90),
      now: now,
    );
    expect(week.map((e) => e.id), ['recent-tarot']);
    expect(ninety.map((e) => e.id), ['recent-tarot', 'mid-coffee']);
  });
}
