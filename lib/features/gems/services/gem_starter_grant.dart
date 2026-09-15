/// One-time starter gems — enough for a single tarot reading.
library;

import '../../../core/data/datasources/local_storage.dart';
import 'gem_wallet_service.dart';

class GemStarterGrant {
  GemStarterGrant(this._wallet, this._storage);

  static const flagKey = 'gem_starter_granted';
  static const operationId = 'gem_starter_v1';

  final GemWalletService _wallet;
  final LocalStorage _storage;

  bool _claimedInMemory = false;

  bool get alreadyGranted =>
      _claimedInMemory || (_storage.getBool(flagKey) ?? false);

  /// Requests the account-scoped server grant. The local flag is UX-only.
  Future<bool> ensureOnce() async {
    if (_wallet.busy) return false;
    _claimedInMemory = true;
    try {
      final result = await _wallet.claimStarter(idempotencyKey: operationId);
      if (result == null) {
        _claimedInMemory = false;
        return false;
      }
      await _storage.setBool(flagKey, true);
      return result.applied && !result.idempotent;
    } catch (_) {
      _claimedInMemory = false;
      return false;
    }
  }
}
