/// Authoritative earn/spend — never negative, never double-spend.
library;

import '../copy/gems_copy.dart';
import '../data/gem_wallet_store.dart';
import '../models/gem_transaction.dart';

class GemSpendException implements Exception {
  const GemSpendException(this.message);
  final String message;
}

class GemWalletService {
  GemWalletService(this._store);

  final GemWalletStore _store;
  bool _busy = false;

  bool get busy => _busy;
  int get balance => _store.balance();
  List<GemTransaction> get history => _store.history();

  bool canSpend(int amount) =>
      amount > 0 && !_busy && balance >= amount;

  Future<int> earn({
    required int amount,
    required String reason,
    String? operationId,
  }) {
    if (amount <= 0) return Future.value(balance);
    return _lockedCommit(
      amount: amount,
      reason: reason,
      type: GemTransactionType.earned,
      operationId: operationId,
    );
  }

  Future<int> spend({
    required int amount,
    required String reason,
    String? operationId,
  }) {
    if (amount <= 0) return Future.value(balance);
    return _lockedCommit(
      amount: -amount,
      reason: reason,
      type: GemTransactionType.spent,
      operationId: operationId,
    );
  }

  /// Acquire the lock synchronously before any await — prevents double spend.
  Future<int> _lockedCommit({
    required int amount,
    required String reason,
    required GemTransactionType type,
    String? operationId,
  }) async {
    if (_busy) throw GemSpendException(GemsCopy.busy);
    _busy = true;
    try {
      if (operationId != null &&
          operationId.isNotEmpty &&
          history.any((t) => t.id == operationId)) {
        return balance;
      }
      final nextBalance = balance + amount;
      if (nextBalance < 0) {
        throw GemSpendException(GemsCopy.insufficient);
      }
      final txId = (operationId != null && operationId.isNotEmpty)
          ? operationId
          : 'gem_${DateTime.now().microsecondsSinceEpoch}';
      await _store.write(
        balance: nextBalance,
        transaction: GemTransaction(
          id: txId,
          createdAt: DateTime.now(),
          amount: amount,
          reason: reason,
          type: type,
        ),
      );
      return _store.balance();
    } finally {
      _busy = false;
    }
  }
}
