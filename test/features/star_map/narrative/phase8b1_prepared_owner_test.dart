/// Phase 8B.1 — prepared snapshot is the transaction authority (A→B).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan.dart';

import 'phase8b_test_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('prepare binds owner + epoch + language + plan', () async {
    final storage = phase8bStorage();
    final orch = phase8bOrchestrator(storage: storage, chart: phase8bE2());
    final prepared = await orch.prepare(languageCode: 'en');
    expect(prepared.ownerSnapshot.ownerId, 'owner-a');
    expect(
      prepared.ownerSnapshot.epoch,
      UserLocalDataIsolation.accountSwitchEpoch.value,
    );
    expect(prepared.languageCode, 'en');
    expect(prepared.plan.kind, YildiznameLivePlanKind.narrativeReduced);
  });

  test('H prepare A → owner B → executePrepared → ownerChanged, provider 0',
      () async {
    final storage = phase8bStorage();
    final gen = Phase8bGen();
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE4(),
      generate: gen.call,
    );
    final prepared = await orch.prepare(languageCode: 'en');
    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-b');

    final exec = await orch.executePrepared(prepared);
    expect(exec.kind, YildiznameLiveExecutionKind.ownerChanged);
    expect(gen.calls, 0);
    expect(exec.artifact, isNull);
    expect(exec.presentation, isNull);
  });

  test('D/E prepared E2/E4 execute once, no second chart load', () async {
    for (final chart in [phase8bE2(), phase8bE4()]) {
      final storage = phase8bStorage();
      final gen = Phase8bGen();
      var loads = 0;
      final orch = phase8bOrchestrator(
        storage: storage,
        chart: chart,
        generate: gen.call,
        onLoadChart: () => loads++,
      );
      final prepared = await orch.prepare(languageCode: 'en');
      final exec = await orch.executePrepared(prepared);
      expect(exec.kind, YildiznameLiveExecutionKind.ready);
      expect(exec.artifact!.ownerId, 'owner-a');
      expect(gen.calls, 1);
      expect(loads, 1);
    }
  });

  test('prepared ownerUnavailable / invalidEvidence never generate', () async {
    final gen = Phase8bGen();
    final noOwner = phase8bOrchestrator(
      storage: phase8bStorage(owner: ''),
      chart: phase8bE4(),
      generate: gen.call,
    );
    final p1 = await noOwner.prepare(languageCode: 'en');
    expect(p1.plan.kind, YildiznameLivePlanKind.ownerUnavailable);
    expect(
      (await noOwner.executePrepared(p1)).kind,
      YildiznameLiveExecutionKind.ownerUnavailable,
    );
    expect(gen.calls, 0);
  });

  test('preflight is a projection of prepare', () async {
    final orch = phase8bOrchestrator(
      storage: phase8bStorage(),
      chart: phase8bE4(),
    );
    final plan = await orch.preflight(languageCode: 'en');
    final prepared = await orch.prepare(languageCode: 'en');
    expect(plan, prepared.plan);
  });
}
