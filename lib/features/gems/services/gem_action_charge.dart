/// Deduct gems once after a successful provider result. Never invent a price.
library;

import '../../../core/data/datasources/local_storage.dart';
import 'gem_wallet_service.dart';

class GemActionCharge {
  GemActionCharge(
    this._wallet,
    this._storage, {
    required this.ledgerKey,
  });

  static const _maxIds = 80;

  final GemWalletService _wallet;
  final LocalStorage _storage;
  final String ledgerKey;
  final Set<String> _inflight = {};

  bool alreadyCharged(String actionId) => _ids().contains(actionId);

  bool canAfford(int cost) => _wallet.canSpend(cost);

  /// `cost == null` → free. Same [actionId] never deducts twice.
  Future<bool> commit({
    required String actionId,
    required int? cost,
    required String reason,
  }) async {
    if (cost == null || cost <= 0) return true;
    if (alreadyCharged(actionId)) return true;
    if (!_inflight.add(actionId)) {
      while (_inflight.contains(actionId)) {
        await Future<void>.delayed(const Duration(milliseconds: 8));
      }
      return alreadyCharged(actionId);
    }
    try {
      if (alreadyCharged(actionId)) return true;
      if (_wallet.busy || !_wallet.canSpend(cost)) return false;
      await _wallet.spend(
        amount: cost,
        reason: reason,
        operationId: actionId,
      );
      await _remember(actionId);
      return true;
    } on GemSpendException {
      return false;
    } finally {
      _inflight.remove(actionId);
    }
  }

  Set<String> _ids() => {...?_storage.getStringList(ledgerKey)};

  Future<void> _remember(String actionId) async {
    await _storage.setStringList(
      ledgerKey,
      [actionId, ..._ids()].take(_maxIds).toList(),
    );
  }
}
