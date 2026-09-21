/// Auth-driven gem wallet hydration with cold-start retries.
library;

import '../controllers/gem_wallet_controller.dart';

/// One auth-driven refresh per owner and ProviderContainer.
class GemWalletHydrationCoordinator {
  final Map<String, Future<void>> _inFlight = {};
  final Set<String> _bootstrapInFlight = {};

  bool beginBootstrap(String ownerId) => _bootstrapInFlight.add(ownerId);

  void endBootstrap(String ownerId) => _bootstrapInFlight.remove(ownerId);

  Future<void> hydrate(String ownerId, GemWalletController controller) {
    final active = _inFlight[ownerId];
    if (active != null) {
      return active.then((_) async {
        // A provider rebuild may have produced a different controller for the
        // SAME uid while the first reload was in flight. Never replay a
        // coordinator-cached balance into that new controller: wallet balance
        // can change after any settle/reward endpoint, so only the server or
        // the owner-bound durable store may be authoritative.
        if (controller.ownerId == ownerId && !controller.authoritative) {
          await controller.reload();
        }
      });
    }
    final future = controller.reload();
    _inFlight[ownerId] = future;
    return future.whenComplete(() {
      if (identical(_inFlight[ownerId], future)) _inFlight.remove(ownerId);
    });
  }

  Future<void> hydrateWithRetry(
    String ownerId,
    GemWalletController controller, {
    int attempts = 8,
    bool Function()? stillCurrent,
  }) async {
    bool current() =>
        controller.ownerId == ownerId && (stillCurrent?.call() ?? true);

    for (var i = 0; i < attempts; i++) {
      if (!current()) return;
      await hydrate(ownerId, controller);
      if (!current() || controller.authoritative) return;
      // Back off hard — App Check rate-limits ("Too many attempts").
      await Future<void>.delayed(Duration(milliseconds: 800 * (i + 1)));
      if (!current()) return;
    }
  }
}
