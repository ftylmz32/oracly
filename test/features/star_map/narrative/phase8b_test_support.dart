/// Phase 8B — orchestrator test harness (ephemeral storage, injectable generate).
library;

import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_deps.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_narrative_live_service.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_request.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_structured_result.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';

import 'fixtures/fake_yildizname_ai.dart';
import 'phase8a_live_plan_support.dart';
import 'phase8b_approved_payload.dart';

LocalStorage phase8bStorage({String owner = 'owner-a'}) =>
    LocalStorage.ephemeral({UserLocalDataIsolation.ownerKey: owner});

class Phase8bFailingCompletion extends YildiznameNarrativeCompletionService {
  Phase8bFailingCompletion(super.repo);

  bool failNext = true;

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
    if (failNext) {
      failNext = false;
      throw StateError('persist_fail');
    }
    return super.complete(
      ownerId: ownerId,
      request: request,
      result: result,
      evidenceFingerprint: evidenceFingerprint,
      semanticFingerprint: semanticFingerprint,
      policyVersion: policyVersion,
      createdAtUtc: createdAtUtc,
    );
  }
}

YildiznameLiveOrchestrator phase8bOrchestrator({
  required LocalStorage storage,
  required BirthChart? chart,
  bool flag = true,
  DateTime? now,
  YildiznameNarrativeCompletionService? completion,
  YildiznameNarrativeGenerate? generate,
  FakeYildiznameAi? ai,
  int Function()? providerCalls,
}) {
  final owner = storage.getString(UserLocalDataIsolation.ownerKey);
  final repo = LocalYildiznameArtifactRepository(storage, ownerId: owner);
  final fake = ai;
  var calls = 0;
  return YildiznameLiveOrchestrator(
    YildiznameLiveOrchestratorDeps(
      storage: storage,
      loadChart: () async => chart,
      repairChart: (c) async => c,
      artifacts: repo,
      completion: completion ?? YildiznameNarrativeCompletionService(repo),
      flagEnabled: () => flag,
      nowUtc: () => now ?? DateTime.utc(2026, 9, 26, 12),
      narrativeAi: fake,
      liveService: fake == null
          ? null
          : YildiznameNarrativeLiveService(ai: fake, enforceFlag: false),
      generateOverride: generate ??
          (fake == null
              ? ({required request, forceRefresh = false}) async {
                  calls += 1;
                  return YildiznameResultParser.parse(
                    phase8bApprovedPayload(request),
                  );
                }
              : null),
      readProviderCallCount: providerCalls ??
          () => fake?.calls.length ?? calls,
      personalDiscoveryLabels: () async => const [],
    ),
  );
}

BirthChart phase8bE2() => phase8aChart(phase8aE2Profile());
BirthChart phase8bE4() => phase8aChart(phase8aE4Profile());
BirthChart phase8bE1() => phase8aChart(phase8aE1Profile());
BirthChart phase8bE3() => phase8aChart(phase8aE3Profile());
