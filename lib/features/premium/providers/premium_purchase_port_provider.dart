/// Billing port provider - real store on mobile when products load.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/domain/repositories/premium_repository.dart';
import '../models/premium_purchase_credentials.dart';
import '../models/premium_store_pending.dart';
import '../services/premium_purchase_port.dart';
import '../services/store_iap_client.dart';
import '../services/premium_store_test_env_io.dart'
    if (dart.library.html) '../services/premium_store_test_env_stub.dart';
import '../services/store_premium_purchase.dart';
import '../services/unavailable_premium_purchase.dart';

/// Mobile: [StorePremiumPurchase] (purchase needs catalogue; restore needs store).
/// Desktop/web/tests: closed store - honest unavailable UI.
final premiumPurchasePortProvider = Provider<PremiumPurchasePort>((ref) {
  if (premiumStoreUnderFlutterTest ||
      !StorePremiumPurchase.supportedPlatform) {
    return const UnavailablePremiumPurchase();
  }
  final port = createStorePremiumPurchase(
    () => ref.read(premiumRepositoryProvider),
  );
  ref.onDispose(() => unawaited(port.dispose()));
  return port;
});

/// The production store port: always wired with durable recovery
/// persistence, so no terminal store event is finished before its proof is
/// saved for the current owner.
StorePremiumPurchase createStorePremiumPurchase(
  PremiumRepository Function() currentRepository, {
  StoreIapClient? client,
  @visibleForTesting
  Duration answerWindow = StorePremiumPurchase.purchaseAnswerWindow,
}) {
  return StorePremiumPurchase(
    client: client,
    answerWindow: answerWindow,
    persistRetryCredentials: (credentials) =>
        persistPurchaseRecovery(currentRepository, credentials),
    persistStorePending: (productId) =>
        recordStorePending(currentRepository, productId),
    clearStorePending: (productId) =>
        settleStorePending(currentRepository, productId),
  );
}

/// Saves store-acknowledged purchase proof as UNVERIFIED recovery material
/// for the CURRENT owner. The repository is resolved at call time because
/// [premiumRepositoryProvider] is rebuilt per owner while this port lives
/// for the whole session. Runs inside the owner-scoped mutation gate so it
/// cannot interleave with an account-switch wipe. Throws when the owner is
/// not isolated: nothing durable was written, so the caller must not finish
/// the store transaction (and never writes into another owner's storage).
Future<void> persistPurchaseRecovery(
  PremiumRepository Function() currentRepository,
  PremiumPurchaseCredentials credentials,
) {
  return UserLocalDataIsolation.runOwnerScopedMutation(() async {
    final repository = currentRepository();
    if (repository is PremiumOwnerBoundary &&
        !(repository as PremiumOwnerBoundary).ownerAccessReady) {
      throw StateError('premium owner boundary not isolated');
    }
    await repository.savePurchaseCredentials(credentials);
  });
}

/// Records an unfinished store transaction for the CURRENT owner, inside
/// the owner gate, so a second purchase stays blocked across restarts. An
/// existing record keeps its original start time.
Future<void> recordStorePending(
  PremiumRepository Function() currentRepository,
  String productId,
) {
  return UserLocalDataIsolation.runOwnerScopedMutation(() async {
    final repository = currentRepository();
    if (repository is! PremiumStorePendingStore) return;
    if (repository is PremiumOwnerBoundary &&
        !(repository as PremiumOwnerBoundary).ownerAccessReady) {
      throw StateError('premium owner boundary not isolated');
    }
    final store = repository as PremiumStorePendingStore;
    final existing = await store.readStorePending();
    if (existing != null && existing.productId == productId) return;
    await store.saveStorePending(
      PremiumStorePending(
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        productId: productId,
        sinceUtc: DateTime.now().toUtc(),
      ),
    );
  });
}

/// Clears the unfinished record once the store answered terminally for the
/// SAME product (purchased with proof saved, declined or cancelled).
Future<void> settleStorePending(
  PremiumRepository Function() currentRepository,
  String productId,
) {
  return UserLocalDataIsolation.runOwnerScopedMutation(() async {
    final repository = currentRepository();
    if (repository is! PremiumStorePendingStore) return;
    if (repository is PremiumOwnerBoundary &&
        !(repository as PremiumOwnerBoundary).ownerAccessReady) {
      return;
    }
    final store = repository as PremiumStorePendingStore;
    final existing = await store.readStorePending();
    if (existing == null || existing.productId != productId) return;
    await store.clearStorePending();
  });
}
