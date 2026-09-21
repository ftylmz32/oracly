/// Gem wallet providers — one balance for the whole app.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/account_deletion_pending_state.dart';
import '../../../core/auth/firebase/firebase_app_check_token.dart';
import '../../../core/providers/backend_providers.dart' as backend;
import '../../ai/production/oracly_ai_providers.dart';
import '../../reading_operation/providers/reading_live_provider.dart';
import '../controllers/gem_wallet_controller.dart';
import '../data/gem_wallet_store.dart';
import '../data/paid_ai_operation_store.dart';
import '../services/gem_starter_grant.dart';
import '../services/gem_wallet_bootstrap.dart';
import '../services/gem_wallet_gateway.dart';
import '../services/gem_wallet_hydration.dart';
import '../services/gem_wallet_owner_bootstrap.dart';
import '../services/gem_wallet_service.dart';
import '../services/paid_ai_operation_coordinator.dart';
import '../services/rewarded_ad_service.dart';

export '../services/gem_wallet_hydration.dart' show GemWalletHydrationCoordinator;

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
    // Keep server commands bound to the uid this service was created for.
    // A stale screen/service surviving an auth switch must never send an old
    // operation using the new Firebase user's live token.
    currentOwnerId: gateway == null ? null : () => gateway.currentUser?.uid,
  );
});

final gemWalletHydrationCoordinatorProvider =
    Provider<GemWalletHydrationCoordinator>((ref) {
  return GemWalletHydrationCoordinator();
});

final gemWalletProvider = ChangeNotifierProvider<GemWalletController>((ref) {
  final service = ref.watch(gemWalletServiceProvider);
  final controller = GemWalletController(service);
  if (!AccountDeletionPendingState.allowsOwnerBoundExperience) {
    return controller;
  }

  // Capture every dependency synchronously while this provider Ref is valid.
  // No delayed/awaited callback below ever calls ref.read after disposal.
  final config = ref.read(aiRuntimeConfigProvider);
  final auth = ref.read(authServiceProvider);
  final tokenManager = ref.read(tokenManagerProvider);
  final liveGateway = ref.read(backend.firebaseAuthGatewayProvider);
  final coordinator = ref.read(gemWalletHydrationCoordinatorProvider);
  final starter = ref.read(gemStarterGrantProvider);

  var disposed = false;
  Timer? retryTimer;
  ref.onDispose(() {
    disposed = true;
    retryTimer?.cancel();
    retryTimer = null;
  });

  bool ownerStillCurrent(String ownerId) {
    if (disposed ||
        !AccountDeletionPendingState.allowsOwnerBoundExperience ||
        controller.ownerId != ownerId) {
      return false;
    }
    final liveOwner = liveGateway?.currentUser?.uid ?? auth.currentUserId;
    return liveOwner == ownerId;
  }

  Future<void> bootOwner(String ownerId) async {
    if (!ownerStillCurrent(ownerId)) return;
    retryTimer?.cancel();
    retryTimer = null;

    final outcome = await bootstrapGemWalletOwner(
      ownerId: ownerId,
      controller: controller,
      wallet: service,
      coordinator: coordinator,
      config: config,
      auth: auth,
      accessToken: ({bool forceRefresh = false}) =>
          tokenManager.getAccessToken(forceRefresh: forceRefresh),
      appCheckToken: ({bool forceRefresh = false}) =>
          FirebaseAppCheckToken.resolve(forceRefresh: forceRefresh),
      liveGateway: liveGateway,
      ensureStarter: starter.ensureOnce,
      isOwnerCurrent: () => ownerStillCurrent(ownerId),
    );

    // Provider disposal/account switch can happen while bootstrap awaits.
    // Never create a timer after disposal; the old owner gets no second life.
    if (!ownerStillCurrent(ownerId)) return;
    if (outcome == GemWalletOwnerBootstrapOutcome.deferredNotReady) {
      retryTimer = Timer(const Duration(seconds: 12), () {
        if (!ownerStillCurrent(ownerId)) return;
        unawaited(bootOwner(ownerId));
      });
    }
  }

  ref.listen(backend.firebaseAuthUserProvider, (_, next) {
    if (disposed ||
        !AccountDeletionPendingState.allowsOwnerBoundExperience) {
      return;
    }
    final uid = next.valueOrNull?.uid;
    if (uid == null || uid.isEmpty || controller.ownerId != uid) return;
    unawaited(bootOwner(uid));
  });

  final ownerId = service.ownerId;
  if (ownerId != null && ownerId.isNotEmpty) {
    Future.microtask(() => bootOwner(ownerId));
  } else {
    // Auth-late bootstrap: use only captured dependencies. Once anonymous
    // auth becomes real, firebaseAuthUserProvider rebuild/listen owns wallet
    // hydration for that concrete uid.
    Future.microtask(() async {
      if (disposed ||
          !AccountDeletionPendingState.allowsOwnerBoundExperience) {
        return;
      }
      await GemWalletBootstrap.ensureReady(
        config: config,
        auth: auth,
        accessToken: ({bool forceRefresh = false}) =>
            tokenManager.getAccessToken(forceRefresh: forceRefresh),
        appCheckToken: ({bool forceRefresh = false}) =>
            FirebaseAppCheckToken.resolve(forceRefresh: forceRefresh),
        liveGateway: liveGateway,
      );
    });
  }
  return controller;
});

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

final rewardedAdProvider =
    ChangeNotifierProvider.autoDispose<RewardedAdService?>((ref) {
  return null;
});
