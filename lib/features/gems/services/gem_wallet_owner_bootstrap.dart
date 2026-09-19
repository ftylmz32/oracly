/// Owner-scoped gem wallet bootstrap after auth is ready.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/firebase/firebase_app_check_token.dart';
import '../../../core/providers/backend_providers.dart' as backend;
import '../../ai/production/oracly_ai_providers.dart';
import '../controllers/gem_wallet_controller.dart';
import 'gem_economy_live_probe.dart';
import 'gem_wallet_bootstrap.dart';
import 'gem_wallet_hydration.dart';
import 'gem_wallet_service.dart';

Future<void> bootstrapGemWalletOwner({
  required Ref ref,
  required String ownerId,
  required GemWalletController controller,
  required GemWalletService wallet,
  required GemWalletHydrationCoordinator coordinator,
  required Future<void> Function() ensureStarter,
}) async {
  if (!coordinator.beginBootstrap(ownerId)) return;
  try {
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
    if (!ready) {
      print('[GemWallet] bootstrap not ready for $ownerId — defer');
      Future<void>.delayed(const Duration(seconds: 12), () {
        unawaited(
          bootstrapGemWalletOwner(
            ref: ref,
            ownerId: ownerId,
            controller: controller,
            wallet: wallet,
            coordinator: coordinator,
            ensureStarter: ensureStarter,
          ),
        );
      });
      return;
    }
    print('[GemWallet] bootstrap ready owner=$ownerId');
    await coordinator.hydrateWithRetry(ownerId, controller);
    try {
      await ensureStarter();
    } catch (e) {
      print('[GemWallet] starter grant error: $e');
    }
    final cached =
        controller.ownerId == ownerId ? wallet.cachedBalance : null;
    if (cached != null) {
      await controller.acceptAuthoritativeBalance(cached);
    } else if (!controller.authoritative) {
      await controller.reload();
    }
    unawaited(
      GemEconomyLiveProbe.runIfEnabled(
        wallet: wallet,
        controller: controller,
      ),
    );
  } finally {
    coordinator.endBootstrap(ownerId);
  }
}
