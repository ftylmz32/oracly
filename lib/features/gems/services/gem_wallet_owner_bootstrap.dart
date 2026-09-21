/// Owner-scoped gem wallet bootstrap after auth is ready.
library;

import '../../../core/auth/auth_service.dart';
import '../../../core/auth/firebase/firebase_auth_gateway.dart';
import '../../ai/production/ai_runtime_config.dart';
import '../../ai/production/transport/ai_token_reader.dart';
import '../controllers/gem_wallet_controller.dart';
import 'gem_economy_live_probe.dart';
import 'gem_wallet_bootstrap.dart';
import 'gem_wallet_hydration.dart';
import 'gem_wallet_service.dart';

enum GemWalletOwnerBootstrapOutcome {
  completed,
  deferredNotReady,
  staleOwner,
  alreadyInFlight,
}

Future<GemWalletOwnerBootstrapOutcome> bootstrapGemWalletOwner({
  required String ownerId,
  required GemWalletController controller,
  required GemWalletService wallet,
  required GemWalletHydrationCoordinator coordinator,
  required AiRuntimeConfig config,
  required AuthService auth,
  required AiTokenReader accessToken,
  AiTokenReader? appCheckToken,
  FirebaseAuthGateway? liveGateway,
  required Future<void> Function() ensureStarter,
  required bool Function() isOwnerCurrent,
}) async {
  if (!coordinator.beginBootstrap(ownerId)) {
    return GemWalletOwnerBootstrapOutcome.alreadyInFlight;
  }
  try {
    // The provider that launched this work may already have been replaced by
    // an auth-owner change. Never let an old owner task touch network/cache.
    if (!isOwnerCurrent()) {
      return GemWalletOwnerBootstrapOutcome.staleOwner;
    }

    final ready = await GemWalletBootstrap.ensureReady(
      config: config,
      auth: auth,
      accessToken: accessToken,
      appCheckToken: appCheckToken,
      liveGateway: liveGateway,
    );
    if (!isOwnerCurrent()) {
      return GemWalletOwnerBootstrapOutcome.staleOwner;
    }
    if (!ready) {
      print('[GemWallet] bootstrap not ready for $ownerId — defer');
      return GemWalletOwnerBootstrapOutcome.deferredNotReady;
    }

    print('[GemWallet] bootstrap ready owner=$ownerId');
    await coordinator.hydrateWithRetry(
      ownerId,
      controller,
      stillCurrent: isOwnerCurrent,
    );
    if (!isOwnerCurrent()) {
      return GemWalletOwnerBootstrapOutcome.staleOwner;
    }

    try {
      await ensureStarter();
    } catch (e) {
      print('[GemWallet] starter grant error: $e');
    }
    if (!isOwnerCurrent()) {
      return GemWalletOwnerBootstrapOutcome.staleOwner;
    }

    final cached =
        controller.ownerId == ownerId ? wallet.cachedBalance : null;
    if (cached != null) {
      // Starter/reward endpoints already persisted the server balance.
      // Reflect that exact owner-bound cache in UI without writing it again.
      controller.acceptHydratedCachedBalance();
    } else if (!controller.authoritative) {
      await controller.reload();
    }
    if (!isOwnerCurrent()) {
      return GemWalletOwnerBootstrapOutcome.staleOwner;
    }

    // Probe is best-effort, but only starts while this owner is still active.
    // It receives captured service/controller instances and never reads a
    // disposed Riverpod Ref.
    // ignore: unawaited_futures
    GemEconomyLiveProbe.runIfEnabled(
      wallet: wallet,
      controller: controller,
    );
    return GemWalletOwnerBootstrapOutcome.completed;
  } finally {
    coordinator.endBootstrap(ownerId);
  }
}
