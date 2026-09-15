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
  Future<PaidAiOperation> begin({
    required PaidAiFeature feature,
    required String ledgerKey,
    required String reason,
    required int? cost,
    String? existingId,
  }) async {
    final amount = cost ?? 0;
    final id = existingId != null && existingId.trim().isNotEmpty
        ? PaidAiOperationId.fromExisting(feature.name, existingId)
        : PaidAiOperationId.create(feature.name);
    final op = PaidAiOperation(
      id: id,
      feature: feature,
      ledgerKey: ledgerKey,
      reason: reason,
      cost: amount,
      status: amount <= 0
          ? PaidAiOperationStatus.settled
          : PaidAiOperationStatus.pending,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
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
      await _store.remove(op.id);
      return true;
    }
    if (op.feature != PaidAiFeature.tarot) return false;
    final result = await _wallet.settleTarot(
      operationId: op.id,
      // The operation path is the server's canonical idempotency identity.
      // Keep this transport key bounded even when an external session id is long.
      idempotencyKey: 'tarot-settle-request-v1',
    );
    if (result == null) {
      try {
        await _wallet.refresh();
      } catch (_) {}
    }
    final ok = result?.applied == true;
    if (ok) {
      await _store.upsert(op.copyWith(status: PaidAiOperationStatus.settled));
    }
    return ok;
  }

  /// After provider success: mark then settle. Never double-charges.
  Future<bool> completeAfterProvider(PaidAiOperation op) async {
    await markProviderOk(op.id);
    return settle(op.copyWith(status: PaidAiOperationStatus.providerOk));
  }

  /// Resume / splash — settle providerOk leftovers; drop stale pending
  /// confirms that never reached provider success (no charge).
  Future<int> reconcile() async {
    var settled = 0;
    for (final op in _store.needingSettle()) {
      if (await settle(op)) settled += 1;
    }
    for (final op in _store.all()) {
      if (op.status == PaidAiOperationStatus.pending && op.isBillable) {
        await abandon(op.id);
      }
    }
    return settled;
  }
}
