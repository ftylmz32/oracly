/// Auth-driven gem wallet hydration with cold-start retries.
library;

import 'dart:async';

import '../controllers/gem_wallet_controller.dart';

/// One auth-driven refresh per owner and ProviderContainer.
class GemWalletHydrationCoordinator {
  final Map<String, Future<bool>> _inFlight = {};
  final Map<String, Completer<void>> _bootstrapInFlight = {};

  bool beginBootstrap(String ownerId) {
    if (_bootstrapInFlight.containsKey(ownerId)) return false;
    _bootstrapInFlight[ownerId] = Completer<void>();
    return true;
  }

  void endBootstrap(String ownerId) =>
      _bootstrapInFlight.remove(ownerId)?.complete();

  /// Completes once the same-owner bootstrap holding the lock (if any)
  /// releases it. Lets a controller that arrived while a predecessor was in
  /// flight take over instead of being left unhydrated.
  Future<void> bootstrapReleased(String ownerId) =>
      _bootstrapInFlight[ownerId]?.future ?? Future<void>.value();

  Future<void> hydrate(String ownerId, GemWalletController controller) async {
    final active = _inFlight[ownerId];
    if (active != null) {
      final succeeded = await active;
      if (controller.ownerId != ownerId || controller.authoritative) return;

      // The first controller's successful GET has just written the same
      // owner-bound durable store. Adopt that exact persisted snapshot in the
      // recreated controller without a second GET. If the shared GET failed
      // (or no durable value exists), retry from the server instead.
      if (succeeded && controller.acceptHydratedCachedBalance()) return;
      await controller.reloadAuthoritatively();
      return;
    }

    final future = controller.reloadAuthoritatively();
    _inFlight[ownerId] = future;
    try {
      await future;
    } finally {
      if (identical(_inFlight[ownerId], future)) _inFlight.remove(ownerId);
    }
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
