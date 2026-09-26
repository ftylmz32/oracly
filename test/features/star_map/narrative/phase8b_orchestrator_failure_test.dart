/// Phase 8B — failure matrix (AI, provider, quality, flag, owner).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_deps.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_narrative_live_failure.dart';

import 'corpus/narrative_fail_corpus.dart';
import 'fixtures/fake_yildizname_ai.dart';
import 'phase8b_test_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('F no Narrative AI capability → aiUnavailable', () async {
    final storage = phase8bStorage();
    final owner = storage.getString(UserLocalDataIsolation.ownerKey);
    final repo = LocalYildiznameArtifactRepository(storage, ownerId: owner);
    final orch = YildiznameLiveOrchestrator(
      YildiznameLiveOrchestratorDeps(
        storage: storage,
        loadChart: () async => phase8bE4(),
        repairChart: (c) async => c,
        artifacts: repo,
        completion: YildiznameNarrativeCompletionService(repo),
        flagEnabled: () => true,
        nowUtc: () => DateTime.utc(2026, 9, 26),
      ),
    );
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.aiUnavailable);
  });

  test('G provider exhausts → generationFailed', () async {
    final storage = phase8bStorage();
    final ai = FakeYildiznameAi(({
      required payload,
      required fingerprint,
      required attempt,
    }) async =>
        failProvider());
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE4(),
      ai: ai,
      generate: null,
    );
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.generationFailed);
    expect(exec.artifact, isNull);
    expect(ai.calls.length, greaterThanOrEqualTo(2));
  });

  test('H quality rejects → generationFailed', () async {
    final storage = phase8bStorage();
    final ai = FakeYildiznameAi(({
      required payload,
      required fingerprint,
      required attempt,
    }) async =>
        okMap(NarrativeFailCorpus.wrongMoonSign()));
    final orch = phase8bOrchestrator(
      storage: storage,
      chart: phase8bE4(),
      ai: ai,
      generate: null,
    );
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.generationFailed);
    expect(exec.artifact, isNull);
  });

  test('N flag disabled before/during generate → flagDisabled', () async {
    final storage = phase8bStorage();
    var enabled = true;
    final owner = storage.getString(UserLocalDataIsolation.ownerKey);
    final repo = LocalYildiznameArtifactRepository(storage, ownerId: owner);
    final orch = YildiznameLiveOrchestrator(
      YildiznameLiveOrchestratorDeps(
        storage: storage,
        loadChart: () async => phase8bE2(),
        repairChart: (c) async => c,
        artifacts: repo,
        completion: YildiznameNarrativeCompletionService(repo),
        flagEnabled: () => enabled,
        nowUtc: () => DateTime.utc(2026, 9, 26),
        generateOverride: ({required request, forceRefresh = false}) async {
          enabled = false;
          throw YildiznameLiveFailure(YildiznameLiveFailureKind.flagDisabled);
        },
      ),
    );
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.flagDisabled);
  });

  test('owner blank → ownerUnavailable', () async {
    final orch = phase8bOrchestrator(
      storage: phase8bStorage(owner: ''),
      chart: phase8bE2(),
    );
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.ownerUnavailable);
  });
}
