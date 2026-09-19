/// Gem wallet providers — one balance for the whole app.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
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
  );
});

final gemWalletHydrationCoordinatorProvider =
    Provider<GemWalletHydrationCoordinator>((ref) {
      return GemWalletHydrationCoordinator();
    });

final gemWalletProvider = ChangeNotifierProvider<GemWalletController>((ref) {
  final service = ref.watch(gemWalletServiceProvider);
  final controller = GemWalletController(service);

  ref.listen(backend.firebaseAuthUserProvider, (_, next) {
    final uid = next.valueOrNull?.uid;
    if (uid == null || uid.isEmpty) return;
    unawaited(_bootstrapOwner(ref, uid, controller));
  });

  final ownerId = service.ownerId;
  Future.microtask(() async {
    if (ownerId != null && ownerId.isNotEmpty) {
      await _bootstrapOwner(ref, ownerId, controller);
      return;
    }
    await GemWalletBootstrap.ensureReady(
      config: ref.read(aiRuntimeConfigProvider),
      auth: ref.read(authServiceProvider),
      accessToken: ({bool forceRefresh = false}) =>
          ref.read(tokenManagerProvider).getAccessToken(
                forceRefresh: forceRefresh,
              ),
      appCheckToken: ({bool forceRefresh = false}) =>
          FirebaseAppCheckToken.resolve(forceRefresh: forceRefresh),
      liveGateway: ref.read(backend.firebaseAuthGatewayProvider),
    );
  });
  return controller;
});

Future<void> _bootstrapOwner(
  Ref ref,
  String ownerId,
  GemWalletController controller,
) async {
  final ready = await GemWalletBootstrap.ensureReady(
    config: ref.read(aiRuntimeConfigProvider),
    auth: ref.read(authServiceProvider),
    accessToken: ({bool forceRefresh = false}) =>
        ref.read(tokenManagerProvider).getAccessToken(
              forceRefresh: forceRefresh,
            ),
    appCheckToken: ({bool forceRefresh = false}) =>
        FirebaseAppCheckToken.resolve(forceRefresh: forceRefresh),
    liveGateway: ref.read(backend.firebaseAuthGatewayProvider),
  );
  if (!ready) debugPrint('[GemWallet] bootstrap not ready for $ownerId');
  await ref
      .read(gemWalletHydrationCoordinatorProvider)
      .hydrateWithRetry(ownerId, controller);
  try {
    await ref.read(gemStarterGrantProvider).ensureOnce();
  } catch (e) {
    debugPrint('[GemWallet] starter grant error: $e');
  }
  final cached = controller.ownerId == ownerId
      ? ref.read(gemWalletServiceProvider).cachedBalance
      : null;
  if (cached != null) {
    await controller.acceptAuthoritativeBalance(cached);
  } else if (!controller.authoritative) {
    await controller.reload();
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

final rewardedAdProvider =
    ChangeNotifierProvider.autoDispose<RewardedAdService?>((ref) {
  return null;
});
