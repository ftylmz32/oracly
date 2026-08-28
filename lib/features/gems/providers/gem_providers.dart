/// Gem wallet providers — one balance for the whole app.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../controllers/gem_wallet_controller.dart';
import '../data/gem_wallet_store.dart';
import '../data/paid_ai_operation_store.dart';
import '../services/gem_starter_grant.dart';
import '../services/gem_wallet_service.dart';
import '../services/paid_ai_operation_coordinator.dart';

final gemWalletStoreProvider = Provider<GemWalletStore>((ref) {
  return GemWalletStore(ref.watch(localStorageProvider));
});

final gemWalletServiceProvider = Provider<GemWalletService>((ref) {
  return GemWalletService(ref.watch(gemWalletStoreProvider));
});

final gemWalletProvider =
    ChangeNotifierProvider<GemWalletController>((ref) {
  return GemWalletController(ref.watch(gemWalletServiceProvider));
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

final paidAiOperationCoordinatorProvider =
    Provider<PaidAiOperationCoordinator>((ref) {
  return PaidAiOperationCoordinator(
    wallet: ref.watch(gemWalletServiceProvider),
    storage: ref.watch(localStorageProvider),
    store: ref.watch(paidAiOperationStoreProvider),
  );
});
