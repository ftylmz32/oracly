/// Auth-driven gem wallet hydration with cold-start retries.
library;

import '../controllers/gem_wallet_controller.dart';

/// One auth-driven refresh per owner and ProviderContainer.
class GemWalletHydrationCoordinator {
  final Map<String, Future<void>> _inFlight = {};
  final Map<String, int> _authoritativeBalances = {};

  Future<void> hydrate(String ownerId, GemWalletController controller) {
    final known = _authoritativeBalances[ownerId];
    if (known != null) return controller.acceptAuthoritativeBalance(known);
    final active = _inFlight[ownerId];
    if (active != null) {
      return active.then((_) async {
        final balance = _authoritativeBalances[ownerId];
        if (balance != null && controller.ownerId == ownerId) {
          await controller.acceptAuthoritativeBalance(balance);
        }
      });
    }
    final future = controller.reload().then((_) {
      if (controller.authoritative && controller.ownerId == ownerId) {
        _authoritativeBalances[ownerId] = controller.balance;
      }
    });
    _inFlight[ownerId] = future;
    return future.whenComplete(() {
      if (identical(_inFlight[ownerId], future)) _inFlight.remove(ownerId);
    });
  }

  Future<void> hydrateWithRetry(
    String ownerId,
    GemWalletController controller, {
    int attempts = 6,
  }) async {
    for (var i = 0; i < attempts; i++) {
      if (controller.ownerId != ownerId) return;
      await hydrate(ownerId, controller);
      if (controller.authoritative) return;
      await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
    }
  }
}
