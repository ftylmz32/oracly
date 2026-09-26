/// Phase 8B.1 — A → B → A: same owner string, changed epoch → ownerChanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator.dart';

import 'phase8b_test_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  late int savedEpoch;
  setUp(() => savedEpoch = UserLocalDataIsolation.accountSwitchEpoch.value);
  tearDown(
    () => UserLocalDataIsolation.accountSwitchEpoch.value = savedEpoch,
  );

  test('I prepare A(epoch N) → A→B→A (epoch N+2) → ownerChanged', () async {
    final storage = phase8bStorage();
    final gen = Phase8bGen();
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE4(),
      generate: gen.call,
    );
    final prepared = await orch.prepare(languageCode: 'en');
    final n = prepared.ownerSnapshot.epoch;

    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-b');
    UserLocalDataIsolation.accountSwitchEpoch.value++;
    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-a');
    UserLocalDataIsolation.accountSwitchEpoch.value++;

    expect(storage.getString(UserLocalDataIsolation.ownerKey), 'owner-a');
    expect(UserLocalDataIsolation.accountSwitchEpoch.value, n + 2);
    expect(prepared.ownerSnapshot.matches(storage), isFalse);

    final exec = await orch.executePrepared(prepared);
    expect(exec.kind, YildiznameLiveExecutionKind.ownerChanged);
    expect(gen.calls, 0);
    expect(exec.artifact, isNull);
    expect(exec.presentation, isNull);
  });

  test('epoch alone changes (same owner) → ownerChanged', () async {
    final storage = phase8bStorage();
    final gen = Phase8bGen();
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE2(),
      generate: gen.call,
    );
    final prepared = await orch.prepare(languageCode: 'en');
    UserLocalDataIsolation.accountSwitchEpoch.value++;
    final exec = await orch.executePrepared(prepared);
    expect(exec.kind, YildiznameLiveExecutionKind.ownerChanged);
    expect(gen.calls, 0);
  });
}
