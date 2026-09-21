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

    final result = await (() async {
      try {
        return await _wallet.claimStarter(idempotencyKey: operationId);
      } catch (_) {
        return null;
      }
    })();
    if (result == null) {
      _claimedInMemory = false;
      return false;
    }

    // The server grant has already been accepted. This flag is UX-only:
    // failure to persist it cannot undo server authority and must not make
    // this process request/represent the starter grant as unclaimed again.
    try {
      await _storage.setBool(flagKey, true);
    } catch (_) {}
    return result.applied && !result.idempotent;
  }
}
