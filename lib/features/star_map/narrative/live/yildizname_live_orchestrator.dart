/// Phase 8B — live Narrative orchestrator (no UI, no BuildContext).
library;

import 'yildizname_live_execution.dart';
import 'yildizname_live_generate.dart';
import 'yildizname_live_orchestrator_deps.dart';
import 'yildizname_live_owner_snapshot.dart';
import 'yildizname_live_persist.dart';
import 'yildizname_live_plan.dart';
import 'yildizname_live_preflight.dart';
import 'yildizname_pending_narrative_completion.dart';

export 'yildizname_live_error_copy.dart';
export 'yildizname_live_execution.dart';
export 'yildizname_pending_narrative_completion.dart';

/// Coordinates frozen Phase 8A plan → live service → durable artifact → presentation.
final class YildiznameLiveOrchestrator {
  YildiznameLiveOrchestrator(this._deps)
      : _preflight = YildiznameLivePreflight(_deps),
        _persist = YildiznameLivePersist(_deps) {
    _generate = YildiznameLiveGenerate(_deps, _persist);
  }

  final YildiznameLiveOrchestratorDeps _deps;
  final YildiznameLivePreflight _preflight;
  final YildiznameLivePersist _persist;
  late final YildiznameLiveGenerate _generate;
  bool _busy = false;

  bool get isBusy => _busy;

  /// Local eligibility only — no provider. Avoids Narrative cinema for legacy.
  Future<YildiznameLivePlan> preflight({required String languageCode}) async {
    if (!_deps.flagEnabled()) return YildiznameLivePlan.legacyLocal();
    final expected = YildiznameLiveOwnerSnapshot.capture(_deps.storage);
    return (await _preflight.plan(
      expected: expected,
      languageCode: languageCode,
    )).plan;
  }

  Future<YildiznameLiveExecution> execute({
    required String languageCode,
    bool forceRefresh = false,
  }) async {
    if (_busy) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.generationFailed,
      );
    }
    _busy = true;
    try {
      return await _run(
        languageCode: languageCode,
        forceRefresh: forceRefresh,
      );
    } finally {
      _busy = false;
    }
  }

  Future<YildiznameLiveExecution> retryPersistence(
    YildiznamePendingNarrativeCompletion pending,
  ) async {
    if (_busy) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.persistencePending,
        pending: pending,
        providerCallCount: pending.providerCallCount,
      );
    }
    _busy = true;
    try {
      return await _persist.complete(pending);
    } finally {
      _busy = false;
    }
  }

  Future<YildiznameLiveExecution> _run({
    required String languageCode,
    required bool forceRefresh,
  }) async {
    if (!_deps.flagEnabled()) return YildiznameLiveExecution.legacyLocal();
    final expected = YildiznameLiveOwnerSnapshot.capture(_deps.storage);
    if (!expected.isValid) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.ownerUnavailable,
      );
    }
    final planned = await _preflight.plan(
      expected: expected,
      languageCode: languageCode,
    );
    final plan = planned.plan;
    if (plan.kind == YildiznameLivePlanKind.legacyLocal) {
      return YildiznameLiveExecution.legacyLocal();
    }
    if (plan.kind == YildiznameLivePlanKind.ownerUnavailable) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.ownerUnavailable,
      );
    }
    if (plan.kind == YildiznameLivePlanKind.invalidEvidence) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.invalidEvidence,
      );
    }
    if (!plan.isNarrativeEligible || plan.request == null) {
      return YildiznameLiveExecution.legacyLocal();
    }
    return _generate.run(
      expected: expected,
      plan: plan,
      languageCode: languageCode,
      forceRefresh: forceRefresh,
    );
  }
}
