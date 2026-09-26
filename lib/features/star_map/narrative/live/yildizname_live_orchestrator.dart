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
import 'yildizname_prepared_live_execution.dart';

export 'yildizname_live_error_copy.dart';
export 'yildizname_live_execution.dart';
export 'yildizname_pending_narrative_completion.dart';
export 'yildizname_prepared_live_execution.dart';

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

  /// Captures owner + epoch ONCE and binds it to the local plan. No provider.
  Future<YildiznamePreparedLiveExecution> prepare({
    required String languageCode,
  }) async {
    final snapshot = YildiznameLiveOwnerSnapshot.capture(_deps.storage);
    final plan = _deps.flagEnabled()
        ? (await _preflight.plan(
            expected: snapshot,
            languageCode: languageCode,
          )).plan
        : YildiznameLivePlan.legacyLocal();
    return YildiznamePreparedLiveExecution(
      ownerSnapshot: snapshot,
      languageCode: languageCode,
      plan: plan,
    );
  }

  /// Compatibility projection of [prepare].
  Future<YildiznameLivePlan> preflight({required String languageCode}) async =>
      (await prepare(languageCode: languageCode)).plan;

  /// Fresh transaction: [prepare] → [executePrepared] (single path).
  Future<YildiznameLiveExecution> execute({
    required String languageCode,
    bool forceRefresh = false,
  }) {
    return _guarded(() async {
      final prepared = await prepare(languageCode: languageCode);
      return _runPrepared(prepared, forceRefresh: forceRefresh);
    });
  }

  /// Runs a prepared transaction under ITS snapshot — never a recaptured one.
  Future<YildiznameLiveExecution> executePrepared(
    YildiznamePreparedLiveExecution prepared, {
    bool forceRefresh = false,
  }) {
    return _guarded(
      () => _runPrepared(prepared, forceRefresh: forceRefresh),
    );
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

  Future<YildiznameLiveExecution> _guarded(
    Future<YildiznameLiveExecution> Function() run,
  ) async {
    if (_busy) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.generationFailed,
      );
    }
    _busy = true;
    try {
      return await run();
    } finally {
      _busy = false;
    }
  }

  Future<YildiznameLiveExecution> _runPrepared(
    YildiznamePreparedLiveExecution prepared, {
    required bool forceRefresh,
  }) async {
    final plan = prepared.plan;
    switch (plan.kind) {
      case YildiznameLivePlanKind.legacyLocal:
        return YildiznameLiveExecution.legacyLocal();
      case YildiznameLivePlanKind.ownerUnavailable:
        return _fail(YildiznameLiveExecutionKind.ownerUnavailable);
      case YildiznameLivePlanKind.invalidEvidence:
        return _fail(YildiznameLiveExecutionKind.invalidEvidence);
      case YildiznameLivePlanKind.narrativeReduced:
      case YildiznameLivePlanKind.narrativeFull:
        break;
    }
    if (!prepared.ownerSnapshot.isValid) {
      return _fail(YildiznameLiveExecutionKind.ownerUnavailable);
    }
    if (plan.request == null) {
      return _fail(YildiznameLiveExecutionKind.invalidEvidence);
    }
    return _generate.run(
      expected: prepared.ownerSnapshot,
      plan: plan,
      languageCode: prepared.languageCode,
      forceRefresh: forceRefresh,
    );
  }

  static YildiznameLiveExecution _fail(YildiznameLiveExecutionKind kind) =>
      YildiznameLiveExecution.failure(kind);
}
