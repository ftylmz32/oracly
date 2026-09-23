/// Phase 4C.1 — owner-safe live Tarot source ids + typed deletion.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../personal_discovery/pde_test_fixtures.dart';
import '../tarot_4c_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late Phase4cHarness h;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    h = Phase4cHarness(LocalStorage(prefs));
  });

  test(
    'F4C-01 owner A cannot see owner B tarot memory via session id',
    () async {
      await setOwner(h.storage, 'A');
      await h.tarot.saveSession(completedSession(id: 'b_session', userId: 'B'));
      await h.memory.upsert(
        readingMemory(sourceId: 'b_session', type: OraclyReadingType.tarot),
      );
      final r = await h.loader().load(currentOwnerId: 'A');
      expect(r.privacyBlocked, isFalse);
      expect(r.snapshot.tarotReadings, isEmpty);
      expect(r.snapshot.connectedMemories, isEmpty);
    },
  );

  test('F4C-01 owner A cannot see owner B journal memory', () async {
    await setOwner(h.storage, 'A');
    await h.readings.saveReading(journalReading(id: 'b_journal', userId: 'B'));
    await h.memory.upsert(
      readingMemory(sourceId: 'b_journal', type: OraclyReadingType.tarot),
    );
    final r = await h.loader().load(currentOwnerId: 'A');
    expect(r.snapshot.tarotReadings, isEmpty);
    expect(r.snapshot.connectedMemories, isEmpty);
  });

  test('F4C-01 linked owner conflict is not live memory authority', () async {
    await setOwner(h.storage, 'A');
    await h.tarot.saveSession(completedSession(id: 's1', userId: 'A'));
    await h.readings.saveReading(
      journalReading(id: 'j1', sessionId: 's1', userId: 'B'),
    );
    await h.memory.upsert(
      readingMemory(sourceId: 'j1', type: OraclyReadingType.tarot),
    );
    final r = await h.loader().load(currentOwnerId: 'A');
    expect(r.snapshot.tarotReadings, isEmpty);
    expect(r.snapshot.connectedMemories, isEmpty);
  });

  test('F4C-02 removeBySourceAndType is type-scoped', () async {
    final memory = OraclyMemoryStore(h.storage);
    await memory.upsert(
      readingMemory(sourceId: 'x', type: OraclyReadingType.tarot),
    );
    await memory.upsert(
      readingMemory(sourceId: 'x', type: OraclyReadingType.coffee),
    );
    await memory.upsert(
      readingMemory(sourceId: 'x', type: OraclyReadingType.dream),
    );
    await memory.removeBySourceAndType('x', OraclyReadingType.tarot);
    final types = memory.all().map((e) => e.source.type).toSet();
    expect(types, {OraclyReadingType.coffee, OraclyReadingType.dream});
  });

  test('F4C-02 Tarot delete preserves same-id Coffee source+memory', () async {
    await setOwner(h.storage, null);
    await h.tarot.saveSession(completedSession(id: 'shared_id'));
    await h.readings.saveReading(
      journalReading(id: 'shared_id', sessionId: 'shared_id'),
    );
    await h.memory.upsert(
      readingMemory(sourceId: 'shared_id', type: OraclyReadingType.tarot),
    );
    await CoffeeReadingStore(
      h.storage,
      memory: h.memory,
    ).save(pdeCoffee('shared_id', 'Fincan'));

    await h.deletion().deleteReading('shared_id');

    expect(await h.history.getAll(), isEmpty);
    expect(await h.tarot.loadAllSessions(), isEmpty);
    expect(
      h.memory.all().where((m) => m.source.type == OraclyReadingType.tarot),
      isEmpty,
    );
    expect(CoffeeReadingStore(h.storage).byId('shared_id'), isNotNull);
    expect(
      h.memory.all().any(
        (m) =>
            m.source.type == OraclyReadingType.coffee &&
            m.source.id == 'shared_id',
      ),
      isTrue,
    );

    final restarted = Phase4cHarness(LocalStorage(prefs));
    expect(CoffeeReadingStore(restarted.storage).byId('shared_id'), isNotNull);
    expect(
      restarted.memory.all().any(
        (m) =>
            m.source.type == OraclyReadingType.coffee &&
            m.source.id == 'shared_id',
      ),
      isTrue,
    );
    expect(
      restarted.memory.all().where(
        (m) => m.source.type == OraclyReadingType.tarot,
      ),
      isEmpty,
    );
  });

  test('F4C-02 Coffee delete preserves same-id Tarot memory', () async {
    await setOwner(h.storage, null);
    await h.memory.upsert(
      readingMemory(sourceId: 'shared_id', type: OraclyReadingType.tarot),
    );
    final coffee = CoffeeReadingStore(h.storage, memory: h.memory);
    await coffee.save(pdeCoffee('shared_id', 'Fincan'));
    await coffee.delete('shared_id');

    expect(CoffeeReadingStore(h.storage).byId('shared_id'), isNull);
    expect(
      h.memory.all().any(
        (m) =>
            m.source.type == OraclyReadingType.coffee &&
            m.source.id == 'shared_id',
      ),
      isFalse,
    );
    expect(
      h.memory.all().any(
        (m) =>
            m.source.type == OraclyReadingType.tarot &&
            m.source.id == 'shared_id',
      ),
      isTrue,
    );
  });

  test('F4C-03 empty session + linked relationship question', () async {
    await setOwner(h.storage, null);
    await h.tarot.saveSession(
      completedSession(
        id: 's_q',
        intention: '',
        topic: null,
        interpretation: 'Session yorum',
      ),
    );
    await h.readings.saveReading(
      journalReading(
        id: 's_q',
        sessionId: 's_q',
        intention: 'What is my partner feeling in this relationship?',
        readingType: 'relationship',
      ),
    );
    final row = (await h.loader().load(
      currentOwnerId: null,
    )).snapshot.tarotReadings.single;
    expect(row.intentionSummary, isNotNull);
    expect(row.intentionSummary, contains('partner'));
    expect(row.questionKind, QuestionKind.relationship);
    expect(row.topicId, 'relationship');
  });

  test('F4C-03 session real question beats linked fallback', () async {
    await setOwner(h.storage, null);
    await h.tarot.saveSession(
      completedSession(
        id: 's_d',
        intention: 'Should I quit this job now?',
        topic: 'career',
      ),
    );
    await h.readings.saveReading(
      journalReading(
        id: 's_d',
        sessionId: 's_d',
        intention: 'What is my partner feeling in this relationship?',
        readingType: 'relationship',
      ),
    );
    final row = (await h.loader().load(
      currentOwnerId: null,
    )).snapshot.tarotReadings.single;
    expect(row.questionKind, QuestionKind.decision);
    expect(row.topicId, 'career');
    expect(row.intentionSummary, contains('quit'));
  });
}
