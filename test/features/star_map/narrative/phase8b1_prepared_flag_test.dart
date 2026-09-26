/// Phase 8B.1 — flag true at prepare, false before execute → flagDisabled.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan.dart';

import 'phase8b_test_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('J prepare(flag true) → flag false → flagDisabled, provider 0',
      () async {
    final storage = phase8bStorage();
    final gen = Phase8bGen();
    var enabled = true;
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE4(),
      generate: gen.call,
      flagReader: () => enabled,
    );
    final prepared = await orch.prepare(languageCode: 'en');
    expect(prepared.plan.kind, YildiznameLivePlanKind.narrativeFull);

    enabled = false;
    final exec = await orch.executePrepared(prepared);
    expect(exec.kind, YildiznameLiveExecutionKind.flagDisabled);
    expect(exec.isLegacy, isFalse);
    expect(gen.calls, 0);
    expect(exec.artifact, isNull);
  });

  test('next NEW action with flag false → legacyLocal', () async {
    var enabled = true;
    final orch = phase8bOrchestrator(
      storage: phase8bStorage(),
      chart: phase8bE4(),
      generate: Phase8bGen().call,
      flagReader: () => enabled,
    );
    enabled = false;
    final prepared = await orch.prepare(languageCode: 'en');
    expect(prepared.isLegacy, isTrue);
    expect(
      (await orch.executePrepared(prepared)).kind,
      YildiznameLiveExecutionKind.legacyLocal,
    );
  });
}
