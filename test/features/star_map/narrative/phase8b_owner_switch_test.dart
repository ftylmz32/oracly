/// Phase 8B — owner/epoch switch red-team (storage mutation, no global epoch leak).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_deps.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_request.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_structured_result.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';

import 'phase8b_approved_payload.dart';
import 'phase8b_test_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('L owner changes during generate → ownerChanged', () async {
    final storage = phase8bStorage();
    final owner = storage.getString(UserLocalDataIsolation.ownerKey);
    final repo = LocalYildiznameArtifactRepository(storage, ownerId: owner);
    final orch = YildiznameLiveOrchestrator(
      YildiznameLiveOrchestratorDeps(
        storage: storage,
        loadChart: () async => phase8bE2(),
        repairChart: (c) async => c,
        artifacts: repo,
        completion: YildiznameNarrativeCompletionService(repo),
        flagEnabled: () => true,
        nowUtc: () => DateTime.utc(2026, 9, 26),
        generateOverride: ({required request, forceRefresh = false}) async {
          await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-b');
          return YildiznameResultParser.parse(phase8bApprovedPayload(request));
        },
        readProviderCallCount: () => 1,
      ),
    );
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.ownerChanged);
    expect(exec.presentation, isNull);
  });

  test('M owner changes after persist → ownerChanged, no live display',
      () async {
    final storage = phase8bStorage();
    final owner = storage.getString(UserLocalDataIsolation.ownerKey);
    final repo = LocalYildiznameArtifactRepository(storage, ownerId: owner);
    final orch = YildiznameLiveOrchestrator(
      YildiznameLiveOrchestratorDeps(
        storage: storage,
        loadChart: () async => phase8bE2(),
        repairChart: (c) async => c,
        artifacts: repo,
        completion: _OwnerFlipCompletion(repo, () async {
          await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-b');
        }),
        flagEnabled: () => true,
        nowUtc: () => DateTime.utc(2026, 9, 26),
        generateOverride: ({required request, forceRefresh = false}) async {
          return YildiznameResultParser.parse(phase8bApprovedPayload(request));
        },
        readProviderCallCount: () => 1,
      ),
    );
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.ownerChanged);
    expect(exec.presentation, isNull);
  });
}

class _OwnerFlipCompletion extends YildiznameNarrativeCompletionService {
  _OwnerFlipCompletion(super.repo, this._onComplete);
  final Future<void> Function() _onComplete;

  @override
  Future<YildiznameArtifact> complete({
    required String ownerId,
    required YildiznameNarrativeRequest request,
    required YildiznameNarrativeStructuredResult result,
    String? evidenceFingerprint,
    String? semanticFingerprint,
    String? policyVersion,
    DateTime? createdAtUtc,
  }) async {
    final artifact = await super.complete(
      ownerId: ownerId,
      request: request,
      result: result,
      evidenceFingerprint: evidenceFingerprint,
      semanticFingerprint: semanticFingerprint,
      policyVersion: policyVersion,
      createdAtUtc: createdAtUtc,
    );
    await _onComplete();
    return artifact;
  }
}
