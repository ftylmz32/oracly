/// Phase 8B — persistence failure + persistence-only retry.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_deps.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';

import 'phase8b_approved_payload.dart';
import 'phase8b_test_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('I/J accepted + save fail → pending; retry persist without provider',
      () async {
    final storage = phase8bStorage();
    final owner = storage.getString(UserLocalDataIsolation.ownerKey);
    final repo = LocalYildiznameArtifactRepository(storage, ownerId: owner);
    final completion = Phase8bFailingCompletion(repo);
    var generates = 0;
    final orch = YildiznameLiveOrchestrator(
      YildiznameLiveOrchestratorDeps(
        storage: storage,
        loadChart: () async => phase8bE2(),
        repairChart: (c) async => c,
        artifacts: repo,
        completion: completion,
        flagEnabled: () => true,
        nowUtc: () => DateTime.utc(2026, 9, 26, 12),
        generateOverride: ({required request, forceRefresh = false}) async {
          generates++;
          return YildiznameResultParser.parse(phase8bApprovedPayload(request));
        },
        readProviderCallCount: () => generates,
        personalDiscoveryLabels: () async => const [],
      ),
    );

    final failed = await orch.execute(languageCode: 'en');
    expect(failed.kind, YildiznameLiveExecutionKind.persistencePending);
    expect(failed.pending, isNotNull);
    expect(failed.providerCallCount, 1);
    expect(generates, 1);
    expect(await repo.getAll(), isEmpty);

    final ok = await orch.retryPersistence(failed.pending!);
    expect(ok.kind, YildiznameLiveExecutionKind.ready);
    expect(generates, 1);
    expect(ok.providerCallCount, 1);
    expect(ok.artifact, isNotNull);
    expect(ok.presentation!.sections.first.body,
        contains('Sun in'));
    expect(ok.pending, isNull);
  });
}
