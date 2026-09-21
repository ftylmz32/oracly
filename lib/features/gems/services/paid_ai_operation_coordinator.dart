/// Paid AI lifecycle: begin → providerOk → settle once → reconcile on resume.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../data/paid_ai_operation_store.dart';
import '../models/paid_ai_operation.dart';
import 'gem_wallet_service.dart';
import 'paid_ai_operation_id.dart';

class PaidAiOperationCoordinator {
  PaidAiOperationCoordinator({
    required this._wallet,
    required LocalStorage storage,
    PaidAiOperationStore? store,
  }) : _store = store ?? PaidAiOperationStore(storage);

  final GemWalletService _wallet;
  final PaidAiOperationStore _store;
  final Map<String, Future<bool>> _settlements = <String, Future<bool>>{};

  PaidAiOperationStore get store => _store;

  /// Free ops return a non-persisted settled stub. Paid ops persist as pending.
  /// Non-Tarot billable features are refused here — there is no settle endpoint.
  Future<PaidAiOperation> begin({
    required PaidAiFeature feature,
    required String ledgerKey,
    required String reason,
    required int? cost,
    String? existingId,
  }) async {
    final amount = cost ?? 0;
    if (amount > 0 && feature != PaidAiFeature.tarot) {
      throw UnsupportedError(
        'PaidAiFeature.${feature.name} has no server settle path; '
        'keep analysisCost null until billing is productized.',
      );
    }
    final id = existingId != null && existingId.trim().isNotEmpty
        ? PaidAiOperationId.fromExisting(feature.name, existingId)
        : PaidAiOperationId.create(feature.name);
    final existing = _store.byId(id);
    if (existing != null &&
        existing.status == PaidAiOperationStatus.settled &&
        existing.feature == feature) {
      return existing;
    }
    final op = PaidAiOperation(
      id: id,
      feature: feature,
      ledgerKey: ledgerKey,
      reason: reason,
      cost: amount,
      status: amount <= 0
          ? PaidAiOperationStatus.settled
          : (existing?.status == PaidAiOperationStatus.providerOk
                ? PaidAiOperationStatus.providerOk
                : PaidAiOperationStatus.pending),
      createdAtMs: existing?.createdAtMs ??
          DateTime.now().millisecondsSinceEpoch,
    );
    if (op.isBillable) await _store.upsert(op);
    return op;
  }

  Future<void> markProviderOk(String operationId) async {
    final current = _store.byId(operationId);
    if (current == null) return;
    if (current.status == PaidAiOperationStatus.settled ||
        current.status == PaidAiOperationStatus.abandoned) {
      return;
    }
    await _store.upsert(
      current.copyWith(status: PaidAiOperationStatus.providerOk),
    );
  }

  Future<void> abandon(String operationId) async {
    final current = _store.byId(operationId);
    if (current == null) return;
    if (current.status == PaidAiOperationStatus.settled) return;
    await _store.upsert(
      current.copyWith(status: PaidAiOperationStatus.abandoned),
    );
  }

  /// Deducts once. Safe to call after resume or lost-network replay.
  Future<bool> settle(PaidAiOperation op) {
    final active = _settlements[op.id];
    if (active != null) return active;
    final future = _settleOnce(op);
    _settlements[op.id] = future;
    return future.whenComplete(() => _settlements.remove(op.id));
  }

  Future<bool> _settleOnce(PaidAiOperation op) async {
    if (!op.isBillable) {
      // Free operations are deliberately never journaled. Do not manufacture
      // a storage dependency by "removing" a row that was never persisted.
      return true;
    }
    if (op.feature != PaidAiFeature.tarot) {
      assert(
        false,
        'Non-Tarot paid settle is unsupported for ${op.feature.name}',
      );
      await abandon(op.id);
      return false;
    }
    if (_store.byId(op.id)?.status == PaidAiOperationStatus.settled) {
      return true;
    }
    final result = await _wallet.settleTarot(
      operationId: op.id,
      // Server debit identity is the path operationId (hashed). This body key
      // only satisfies the purpose-body schema.
      idempotencyKey: 'tarot-settle-request-v1',
    );
    if (result == null) {
      try {
        await _wallet.refresh();
      } catch (_) {}
      return false;
    }
    // Any successful settle envelope (including idempotent replay) is final
    // SERVER truth. If the local settled marker cannot be persisted, keep the
    // older durable providerOk/pending row intact: restart may replay the same
    // settlement idempotently, but we must not tell the live caller the server
    // charge failed after it actually succeeded.
    try {
      await _store.upsert(op.copyWith(status: PaidAiOperationStatus.settled));
    } catch (_) {}
    return true;
  }

  /// After provider success: mark then settle. Never double-charges.
  Future<bool> completeAfterProvider(PaidAiOperation op) async {
    // Promotion is the crash-recovery marker. A storage failure here must not
    // be silently called durable; nevertheless the live process already KNOWS
    // the provider succeeded, so it should still attempt the server-authority
    // settlement immediately. The original pending row remains untouched when
    // promotion fails.
    try {
      await markProviderOk(op.id);
    } catch (_) {}
    try {
      return await settle(op.copyWith(status: PaidAiOperationStatus.providerOk));
    } catch (_) {
      return false;
    }
  }

  /// Resume / splash — settle providerOk leftovers; drop stale pending
  /// confirms that never reached provider success (no charge).
  Future<int> reconcile() async {
    var settled = 0;
    for (final op in _store.needingSettle()) {
      try {
        if (await settle(op)) settled += 1;
      } catch (_) {
        // Per-operation isolation: one corrupt/unwritable local row must not
        // prevent another providerOk operation from being idempotently settled.
      }
    }
    for (final op in _store.all()) {
      if (op.status == PaidAiOperationStatus.pending && op.isBillable) {
        try {
          await abandon(op.id);
        } catch (_) {
          // Leave pending in place when abandonment itself is not durable.
        }
      }
    }
    return settled;
  }
}
