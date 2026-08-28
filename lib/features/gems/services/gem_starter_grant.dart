/// One-time starter gems — enough for a single tarot reading.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../copy/gems_copy.dart';
import '../economy/gem_economy.dart';
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

  /// Grants [GemEconomy.starterGrant] once. Duplicate calls are no-ops.
  ///
  /// Earns before the flag is set so a crash mid-grant cannot permanently
  /// skip the starter pack. [operationId] prevents a double credit if the
  /// flag write is the step that fails.
  Future<bool> ensureOnce() async {
    if (alreadyGranted) return false;
    if (_wallet.busy) return false;
    _claimedInMemory = true;
    try {
      final before = _wallet.balance;
      await _wallet.earn(
        amount: GemEconomy.starterGrant,
        reason: GemsCopy.reasonStarter,
        operationId: operationId,
      );
      await _storage.setBool(flagKey, true);
      return _wallet.balance > before ||
          (_storage.getBool(flagKey) ?? false);
    } catch (_) {
      _claimedInMemory = false;
      return false;
    }
  }
}
