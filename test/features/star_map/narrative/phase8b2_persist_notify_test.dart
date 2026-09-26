/// Phase 8B.2 — persist notification fires only after a verified durable save.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator.dart';

import 'phase8b2_back_support.dart';
import 'phase8b_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('success fires once; semantic duplicate fires again, one row',
      () async {
    final storage = phase8bStorage();
    var fired = 0;
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE4(),
      onPersisted: () => fired++,
    );
    expect((await orch.execute(languageCode: 'en')).isReady, isTrue);
    expect(fired, 1);
    expect((await orch.execute(languageCode: 'en')).isReady, isTrue);
    expect(fired, 2);
    final saved =
        await LocalYildiznameArtifactRepository(storage, ownerId: 'owner-a')
            .getAll();
    expect(saved.length, 1);
  });

  test('save failed → 0; persistence retry success → 1', () async {
    final storage = phase8bStorage();
    var fired = 0;
    final repo = LocalYildiznameArtifactRepository(storage, ownerId: 'owner-a');
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE4(),
      completion: Phase8bFailingCompletion(repo),
      onPersisted: () => fired++,
    );
    final first = await orch.execute(languageCode: 'en');
    expect(first.kind, YildiznameLiveExecutionKind.persistencePending);
    expect(fired, 0);
    final retried = await orch.retryPersistence(first.pending!);
    expect(retried.isReady, isTrue);
    expect(fired, 1);
  });

  test('flag turns false after provider, before save → 0', () async {
    var flag = true;
    var fired = 0;
    final gen = Phase8bGen();
    final orch = phase8bOrchestrator(
      storage: phase8bStorage(),
      chart: phase8bE4(),
      flagReader: () => flag,
      generate: ({required request, forceRefresh = false}) async {
        final r = await gen.call(request: request);
        flag = false;
        return r;
      },
      onPersisted: () => fired++,
    );
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.flagDisabled);
    expect(gen.calls, 1);
    expect(fired, 0);
  });

  test('owner changes during save → artifact removed, 0', () async {
    final storage = phase8bStorage();
    var fired = 0;
    final repo = LocalYildiznameArtifactRepository(storage, ownerId: 'owner-a');
    final completion = Phase8b2HeldCompletion(repo);
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE4(),
      completion: completion,
      onPersisted: () => fired++,
    );
    final run = orch.execute(languageCode: 'en');
    while (completion.calls == 0) {
      await Future<void>.delayed(Duration.zero);
    }
    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-b');
    completion.gate.complete();
    final exec = await run;
    expect(exec.kind, YildiznameLiveExecutionKind.ownerChanged);
    expect(fired, 0);
    expect(await repo.getAll(), isEmpty);
  });
}
