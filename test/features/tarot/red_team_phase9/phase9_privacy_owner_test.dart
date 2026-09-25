/// Phase 9 — owner / privacy isolation (Phase4c harness reuse).
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../narrative_history/tarot_4c_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Phase4cHarness h;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    h = Phase4cHarness(LocalStorage(await SharedPreferences.getInstance()));
  });

  test('A≠B history isolation via loader', () async {
    await setOwner(h.storage, 'A');
    await h.tarot.saveSession(completedSession(id: 's_a', userId: 'A'));
    final forA = await h.loader().load(currentOwnerId: 'A');
    expect(forA.privacyBlocked, isFalse);
    expect(forA.snapshot.tarotReadings.single.ownerId, 'A');

    final forB = await h.loader().load(currentOwnerId: 'B');
    expect(forB.privacyBlocked, isTrue);
    expect(forB.snapshot.tarotReadings, isEmpty);
    expect(forB.snapshot.connectedMemories, isEmpty);
  });

  test('row owner B excluded for current A', () async {
    await setOwner(h.storage, 'A');
    await h.tarot.saveSession(completedSession(id: 's_b', userId: 'B'));
    final r = await h.loader().load(currentOwnerId: 'A');
    expect(r.privacyBlocked, isFalse);
    expect(r.snapshot.tarotReadings, isEmpty);
  });

  test('local non-null with current null → privacyBlocked', () async {
    await setOwner(h.storage, 'A');
    final r = await h.loader().load(currentOwnerId: null);
    expect(r.privacyBlocked, isTrue);
    expect(r.snapshot.tarotReadings, isEmpty);
  });
}
