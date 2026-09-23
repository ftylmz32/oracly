/// Phase 4C red-team — owner isolation matrix.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tarot_4c_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Phase4cHarness h;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    h = Phase4cHarness(LocalStorage(await SharedPreferences.getInstance()));
  });

  test('A: local A / current A / session A → include', () async {
    await setOwner(h.storage, 'A');
    await h.tarot.saveSession(completedSession(id: 's', userId: 'A'));
    final r = await h.loader().load(currentOwnerId: 'A');
    expect(r.privacyBlocked, isFalse);
    expect(r.snapshot.tarotReadings.single.ownerId, 'A');
  });

  test('B: local A / current B → privacyBlocked empty', () async {
    await setOwner(h.storage, 'A');
    await h.tarot.saveSession(completedSession(id: 's', userId: 'A'));
    final r = await h.loader().load(currentOwnerId: 'B');
    expect(r.privacyBlocked, isTrue);
    expect(r.snapshot.tarotReadings, isEmpty);
    expect(r.snapshot.connectedMemories, isEmpty);
  });

  test('C: null/null ownerless → include', () async {
    await setOwner(h.storage, null);
    await h.tarot.saveSession(completedSession(id: 's', userId: null));
    final r = await h.loader().load(currentOwnerId: null);
    expect(r.privacyBlocked, isFalse);
    expect(r.snapshot.tarotReadings, hasLength(1));
  });

  test('D: owner-bound + ownerless legacy → exclude', () async {
    await setOwner(h.storage, 'A');
    await h.readings.saveReading(journalReading(id: 'leg', userId: null));
    final r = await h.loader().load(currentOwnerId: 'A');
    expect(r.snapshot.tarotReadings, isEmpty);
  });

  test('E: row owner B excluded for current A', () async {
    await setOwner(h.storage, 'A');
    await h.tarot.saveSession(completedSession(id: 's', userId: 'B'));
    final r = await h.loader().load(currentOwnerId: 'A');
    expect(r.privacyBlocked, isFalse);
    expect(r.snapshot.tarotReadings, isEmpty);
  });

  test('F: linked owner conflict drops reading', () async {
    await setOwner(h.storage, 'A');
    await h.tarot.saveSession(completedSession(id: 's', userId: 'A'));
    await h.readings.saveReading(
      journalReading(id: 's', sessionId: 's', userId: 'B'),
    );
    final r = await h.loader().load(currentOwnerId: 'A');
    expect(r.snapshot.tarotReadings, isEmpty);
  });

  test('local non-null with current null → privacyBlocked', () async {
    await setOwner(h.storage, 'A');
    final r = await h.loader().load(currentOwnerId: null);
    expect(r.privacyBlocked, isTrue);
    expect(r.snapshot.tarotReadings, isEmpty);
  });
}
