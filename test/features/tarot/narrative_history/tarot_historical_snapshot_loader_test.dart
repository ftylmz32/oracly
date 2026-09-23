/// Phase 4C — snapshot loader owner boundary + privacyBlocked.
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

  late Phase4cHarness h;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    h = Phase4cHarness(LocalStorage(await SharedPreferences.getInstance()));
  });

  test('owner match includes session + live connected memory', () async {
    await setOwner(h.storage, 'A');
    await h.tarot.saveSession(completedSession(id: 's1', userId: 'A'));
    await CoffeeReadingStore(
      h.storage,
      memory: h.memory,
    ).save(pdeCoffee('c1', 'Kahve'));
    await h.memory.upsert(
      readingMemory(sourceId: 'c1', type: OraclyReadingType.coffee),
    );

    final result = await h.loader().load(currentOwnerId: 'A');
    expect(result.privacyBlocked, isFalse);
    expect(result.snapshot.tarotReadings, hasLength(1));
    expect(result.snapshot.connectedMemories, hasLength(1));
  });

  test('owner mismatch → privacyBlocked + empty', () async {
    await setOwner(h.storage, 'A');
    await h.tarot.saveSession(completedSession(id: 's1', userId: 'A'));

    final result = await h.loader().load(currentOwnerId: 'B');
    expect(result.privacyBlocked, isTrue);
    expect(result.snapshot.tarotReadings, isEmpty);
    expect(result.snapshot.connectedMemories, isEmpty);
  });

  test('null/null ownerless row included', () async {
    await setOwner(h.storage, null);
    await h.tarot.saveSession(completedSession(id: 's1', userId: null));
    final result = await h.loader().load(currentOwnerId: null);
    expect(result.privacyBlocked, isFalse);
    expect(result.snapshot.tarotReadings, hasLength(1));
  });

  test('owner-bound excludes ownerless legacy', () async {
    await setOwner(h.storage, 'A');
    await h.readings.saveReading(journalReading(id: 'leg'));
    final result = await h.loader().load(currentOwnerId: 'A');
    expect(result.privacyBlocked, isFalse);
    expect(result.snapshot.tarotReadings, isEmpty);
  });

  test('deterministic ordering', () async {
    await setOwner(h.storage, null);
    await h.tarot.saveSession(
      completedSession(id: 'b', at: DateTime.utc(2026, 8, 11)),
    );
    await h.tarot.saveSession(
      completedSession(id: 'a', at: DateTime.utc(2026, 8, 11)),
    );
    await h.tarot.saveSession(
      completedSession(id: 'c', at: DateTime.utc(2026, 8, 12)),
    );
    final ids = (await h.loader().load(
      currentOwnerId: null,
    )).snapshot.tarotReadings.map((e) => e.readingId).toList();
    expect(ids, ['c', 'a', 'b']);
  });
}
