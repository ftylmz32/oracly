/// Phase 8B — Narrative generate + owner/flag checkpoints around the provider.
library;

import 'yildizname_narrative_live_failure.dart';
import '../request/yildizname_request_fingerprint.dart';
import '../result/yildizname_narrative_structured_result.dart';
import 'yildizname_live_execution.dart';
import 'yildizname_live_orchestrator_deps.dart';
import 'yildizname_live_owner_snapshot.dart';
import 'yildizname_live_persist.dart';
import 'yildizname_live_plan.dart';
import 'yildizname_pending_narrative_completion.dart';

final class YildiznameLiveGenerate {
  YildiznameLiveGenerate(this._deps, this._persist);

  final YildiznameLiveOrchestratorDeps _deps;
  final YildiznameLivePersist _persist;

  Future<YildiznameLiveExecution> run({
    required YildiznameLiveOwnerSnapshot expected,
    required YildiznameLivePlan plan,
    required String languageCode,
    required bool forceRefresh,
  }) async {
    final generate = _deps.resolveGenerate();
    if (generate == null) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.aiUnavailable,
      );
    }
    if (!expected.matches(_deps.storage)) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.ownerChanged,
      );
    }
    if (!_deps.flagEnabled()) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.flagDisabled,
      );
    }

    final YildiznameNarrativeStructuredResult result;
    try {
      result = await generate(
        request: plan.request!,
        forceRefresh: forceRefresh,
      );
    } on YildiznameLiveFailure catch (e) {
      if (e.kind == YildiznameLiveFailureKind.flagDisabled) {
        return YildiznameLiveExecution.failure(
          YildiznameLiveExecutionKind.flagDisabled,
        );
      }
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.generationFailed,
        providerCallCount: _deps.readProviderCallCount(),
      );
    } catch (_) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.generationFailed,
        providerCallCount: _deps.readProviderCallCount(),
      );
    }

    final calls = _deps.readProviderCallCount();
    if (!expected.matches(_deps.storage)) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.ownerChanged,
        providerCallCount: calls,
      );
    }
    if (!_deps.flagEnabled()) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.flagDisabled,
        providerCallCount: calls,
      );
    }

    final pending = YildiznamePendingNarrativeCompletion(
      ownerId: expected.ownerId,
      ownerEpoch: expected.epoch,
      request: plan.request!,
      result: result,
      evidenceFingerprint: plan.evidenceFingerprint!,
      semanticFingerprint: YildiznameRequestFingerprint.of(plan.request!),
      createdAtUtc: _deps.nowUtc().toUtc(),
      languageCode: languageCode,
      providerCallCount: calls,
    );
    return _persist.complete(pending, expected: expected);
  }
}
