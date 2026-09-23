/// Phase 4C.2 — strict session-backed Tarot live-source aliases (H17).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_history_source_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tarot_4c_test_support.dart';

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

  Future<Set<String>> liveIds() async {
    final r = await TarotHistorySourceAdapter(
      history: h.history,
      tarotRepository: h.tarot,
    ).load(currentOwnerId: null);
    return r.liveTarotSourceIds;
  }

  test(
    'normal dual-store live ids are session.id + ReadingModel.id only',
    () async {
      await h.tarot.saveSession(completedSession(id: 'session_1'));
      await h.readings.saveReading(
        journalReading(id: 'journal_1', sessionId: 'session_1'),
      );
      expect(await liveIds(), {'session_1', 'journal_1'});

      await h.memory.upsert(
        readingMemory(sourceId: 'journal_1', type: OraclyReadingType.tarot),
      );
      final snap = await h.loader().load(currentOwnerId: null);
      expect(snap.snapshot.tarotReadings, hasLength(1));
      expect(snap.snapshot.connectedMemories.map((e) => e.sourceId), [
        'journal_1',
      ]);
    },
  );

  test('same-id session/journal live set is singleton', () async {
    await h.tarot.saveSession(completedSession(id: 'session_1'));
    await h.readings.saveReading(
      journalReading(id: 'session_1', sessionId: 'session_1'),
    );
    expect(await liveIds(), {'session_1'});
  });

  test('corrupt linked.sessionId never becomes live alias', () async {
    await h.tarot.saveSession(completedSession(id: 'session_live'));
    await h.readings.saveReading(
      journalReading(id: 'session_live', sessionId: 'session_deleted'),
    );
    expect(await liveIds(), {'session_live'});
    expect(await liveIds(), isNot(contains('session_deleted')));
  });

  test('stale memory via corrupt alias is excluded; restart same', () async {
    await h.tarot.saveSession(completedSession(id: 'session_live'));
    await h.readings.saveReading(
      journalReading(id: 'session_live', sessionId: 'session_deleted'),
    );
    await h.memory.upsert(
      readingMemory(sourceId: 'session_deleted', type: OraclyReadingType.tarot),
    );

    final snap = await h.loader().load(currentOwnerId: null);
    expect(snap.snapshot.tarotReadings.single.readingId, 'session_live');
    expect(snap.snapshot.connectedMemories, isEmpty);
    expect(snap.skippedMissingSource, greaterThan(0));

    final restarted = Phase4cHarness(LocalStorage(prefs));
    final again = await restarted.loader().load(currentOwnerId: null);
    expect(again.snapshot.tarotReadings.single.readingId, 'session_live');
    expect(again.snapshot.connectedMemories, isEmpty);
  });

  test('owner isolation still excludes foreign live aliases', () async {
    await setOwner(h.storage, 'A');
    await h.tarot.saveSession(
      completedSession(id: 'session_live', userId: 'B'),
    );
    await h.readings.saveReading(
      journalReading(
        id: 'session_live',
        sessionId: 'session_deleted',
        userId: 'B',
      ),
    );
    await h.memory.upsert(
      readingMemory(sourceId: 'session_deleted', type: OraclyReadingType.tarot),
    );
    final snap = await h.loader().load(currentOwnerId: 'A');
    expect(snap.snapshot.tarotReadings, isEmpty);
    expect(snap.snapshot.connectedMemories, isEmpty);
  });
}
