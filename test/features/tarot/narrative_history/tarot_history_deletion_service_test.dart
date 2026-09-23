/// Phase 4C — TarotHistoryDeletionService coupling + restart integrity.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../personal_discovery/pde_test_fixtures.dart';
import 'tarot_4c_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late Phase4cHarness h;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    h = Phase4cHarness(LocalStorage(prefs));
    await setOwner(h.storage, null);
  });

  test(
    'delete by session id removes journal+session+memory; restart clean',
    () async {
      await h.tarot.saveSession(completedSession(id: 'session_1'));
      await h.readings.saveReading(
        journalReading(id: 'session_1', sessionId: 'session_1'),
      );
      await h.memory.upsert(
        readingMemory(sourceId: 'session_1', type: OraclyReadingType.tarot),
      );

      await h.deletion().deleteReading('session_1');

      expect(await h.history.getAll(), isEmpty);
      expect(await h.tarot.loadAllSessions(), isEmpty);
      expect(h.memory.all(), isEmpty);

      final restarted = Phase4cHarness(LocalStorage(prefs));
      expect(await restarted.history.getAll(), isEmpty);
      expect(await restarted.tarot.loadAllSessions(), isEmpty);
      expect(restarted.memory.all(), isEmpty);

      final snap = await restarted.loader().load(currentOwnerId: null);
      expect(snap.snapshot.tarotReadings, isEmpty);
      expect(snap.snapshot.connectedMemories, isEmpty);
    },
  );

  test('delete by journal id also removes session + memory', () async {
    await h.tarot.saveSession(completedSession(id: 'session_1'));
    await h.readings.saveReading(
      journalReading(id: 'journal_1', sessionId: 'session_1'),
    );
    await h.memory.upsert(
      readingMemory(sourceId: 'journal_1', type: OraclyReadingType.tarot),
    );

    await h.deletion().deleteReading('journal_1');

    expect(await h.history.getAll(), isEmpty);
    expect(await h.tarot.loadAllSessions(), isEmpty);
    expect(h.memory.all(), isEmpty);
  });

  test('delete by session id when memory keyed by journal id', () async {
    await h.tarot.saveSession(completedSession(id: 'session_1'));
    await h.readings.saveReading(
      journalReading(id: 'journal_1', sessionId: 'session_1'),
    );
    await h.memory.upsert(
      readingMemory(sourceId: 'journal_1', type: OraclyReadingType.tarot),
    );

    await h.deletion().deleteReading('session_1');

    expect(await h.history.getAll(), isEmpty);
    expect(await h.tarot.loadAllSessions(), isEmpty);
    expect(h.memory.all(), isEmpty);
  });

  test('unrelated Tarot reading and coffee survive', () async {
    await h.tarot.saveSession(completedSession(id: 'A'));
    await h.readings.saveReading(journalReading(id: 'A', sessionId: 'A'));
    await h.memory.upsert(
      readingMemory(sourceId: 'A', type: OraclyReadingType.tarot),
    );

    await h.tarot.saveSession(completedSession(id: 'B'));
    await h.readings.saveReading(journalReading(id: 'B', sessionId: 'B'));
    await h.memory.upsert(
      readingMemory(sourceId: 'B', type: OraclyReadingType.tarot),
    );

    await CoffeeReadingStore(
      h.storage,
      memory: h.memory,
    ).save(pdeCoffee('c1', 'Kahve'));

    await h.deletion().deleteReading('A');

    expect((await h.history.getAll()).map((e) => e.id), ['B']);
    expect((await h.tarot.loadAllSessions()).map((e) => e.id), ['B']);
    expect(
      h.memory.all().map((e) => e.source.id).toSet(),
      containsAll(['B', 'c1']),
    );
  });
}
