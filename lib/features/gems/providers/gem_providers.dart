/// Gem wallet providers — one balance for the whole app.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/providers/backend_providers.dart' as backend;
import '../controllers/gem_wallet_controller.dart';
import '../data/gem_wallet_store.dart';
import '../data/paid_ai_operation_store.dart';
import '../services/gem_starter_grant.dart';
import '../services/gem_wallet_gateway.dart';
import '../services/gem_wallet_service.dart';
import '../services/paid_ai_operation_coordinator.dart';
import '../services/rewarded_ad_service.dart';
import '../../reading_operation/providers/reading_live_provider.dart';

final gemWalletStoreProvider = Provider<GemWalletStore>((ref) {
  return GemWalletStore(ref.watch(localStorageProvider));
});

final gemWalletServiceProvider = Provider<GemWalletService>((ref) {
  final sender = ref.watch(readingOperationSenderProvider);
  final gateway = ref.watch(backend.firebaseAuthGatewayProvider);
  final authUser = ref.watch(backend.firebaseAuthUserProvider);
  final ownerId = authUser.valueOrNull?.uid ?? gateway?.currentUser?.uid;
  return GemWalletService(
    ref.watch(gemWalletStoreProvider),
    gateway: sender == null ? null : GemWalletGateway(sender),
    ownerId: ownerId,
    requireOwner: true,
  );
});

final gemWalletHydrationCoordinatorProvider =
    Provider<GemWalletHydrationCoordinator>((ref) {
      return GemWalletHydrationCoordinator();
    });

final gemWalletProvider = ChangeNotifierProvider<GemWalletController>((ref) {
  final controller = GemWalletController(ref.watch(gemWalletServiceProvider));
  final ownerId = controller.ownerId;
  if (ownerId != null) {
    Future.microtask(
      () => ref
          .read(gemWalletHydrationCoordinatorProvider)
          .hydrate(ownerId, controller),
    );
  }
  return controller;
});

/// One auth-driven refresh per owner and ProviderContainer. Concurrent
/// provider/widget recreation joins the same request instead of creating a
/// refresh storm. Failures are deliberately retryable.
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
}

final gemStarterGrantProvider = Provider<GemStarterGrant>((ref) {
  return GemStarterGrant(
    ref.watch(gemWalletServiceProvider),
    ref.watch(localStorageProvider),
  );
});

final paidAiOperationStoreProvider = Provider<PaidAiOperationStore>((ref) {
  return PaidAiOperationStore(ref.watch(localStorageProvider));
});

final paidAiOperationCoordinatorProvider = Provider<PaidAiOperationCoordinator>(
  (ref) {
    return PaidAiOperationCoordinator(
      wallet: ref.watch(gemWalletServiceProvider),
      storage: ref.watch(localStorageProvider),
      store: ref.watch(paidAiOperationStoreProvider),
    );
  },
);

/// Rewarded ads are not shipping in this release -- no ad SDK is compiled
/// in (see pubspec.yaml), so there is no [RewardedAdPort] implementation to
/// construct. [RewardedAdService] and its port interface stay in place,
/// dormant, for whenever this feature is revisited; this provider staying
/// `null` is what keeps [GemsRewardedAdCard] permanently collapsed.
final rewardedAdProvider = ChangeNotifierProvider.autoDispose<RewardedAdService?>((ref) {
  return null;
});
