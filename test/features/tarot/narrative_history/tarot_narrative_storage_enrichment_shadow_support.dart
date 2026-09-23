/// Shared seed helpers for Phase 4D shadow integration tests.
library;

import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';

import '../../personal_discovery/pde_test_fixtures.dart';
import 'tarot_4c_test_support.dart';

Future<void> seedRichHistory(Phase4cHarness h, {String? ownerId}) async {
  final histAt = DateTime.utc(2026, 9, 10, 12);
  await setOwner(h.storage, ownerId);
  await h.tarot.saveSession(
    completedSession(id: 'hist_s1', userId: ownerId, at: histAt),
  );
  await h.readings.saveReading(
    journalReading(
      id: 'hist_s1',
      sessionId: 'hist_s1',
      userId: ownerId,
      at: histAt,
      intention: 'relationship partner loyalty stay',
      readingType: 'relationship',
    ),
  );
  await CoffeeReadingStore(h.storage, memory: h.memory).save(
    pdeCoffee('coffee_1', 'relationship partner loyalty trust', at: histAt),
  );
  await h.memory.upsert(
    readingMemory(
      sourceId: 'coffee_1',
      type: OraclyReadingType.coffee,
      summary: 'relationship partner loyalty trust reflection',
      themes: const ['ilişki'],
      at: histAt,
    ),
  );
  await h.dreams.save(
    pdeDream(
      'dream_1',
      'relationship partner loyalty trust mirror',
      at: histAt.subtract(const Duration(days: 1)),
    ),
  );
  await h.memory.upsert(
    readingMemory(
      sourceId: 'dream_1',
      type: OraclyReadingType.dream,
      summary: 'relationship partner loyalty trust mirror',
      themes: const ['ilişki'],
      at: histAt.subtract(const Duration(days: 1)),
    ),
  );
}
