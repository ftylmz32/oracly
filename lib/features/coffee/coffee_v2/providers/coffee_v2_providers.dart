/// Coffee V2 guided-capture providers (Phase 2C2). Additive only — reuses
/// the SAME `readingFeatureRunnerProvider`/`readingOperationSenderProvider`/
/// `coffeeExperienceServiceProvider`/`localStorageProvider`/`gemWalletProvider`
/// legacy Coffee already depends on. Nothing here duplicates auth/network
/// wiring or the Gem/wait economy.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/providers/backend_providers.dart'
    show firebaseAuthGatewayProvider, firebaseAuthUserProvider;
import '../../../gems/providers/gem_providers.dart';
import '../../../reading_operation/models/reading_operation_status.dart';
import '../../../reading_operation/providers/reading_live_provider.dart';
import '../../../reading_operation/services/reading_staged_image_gateway.dart';
import '../../providers/coffee_providers.dart';
import '../controllers/coffee_v2_flow_controller.dart';
import '../services/coffee_v2_submission_controller.dart';
import '../services/coffee_v2_submission_store.dart';

final coffeeV2StagedImageGatewayProvider = Provider<ReadingStagedImageGateway?>(
  (ref) {
    final send = ref.watch(readingOperationSenderProvider);
    if (send == null) return null;
    return ReadingStagedImageGateway(send);
  },
);

final coffeeV2SubmissionStoreProvider = Provider<CoffeeV2SubmissionStore>((
  ref,
) {
  // Stable instance — resolve owner at read/write time so auth readiness
  // does not recreate the flow controller and wipe in-progress captures.
  return CoffeeV2SubmissionStore(
    ref.watch(localStorageProvider),
    ownerResolver: () {
      final authUser = ref.read(firebaseAuthUserProvider);
      final gateway = ref.read(firebaseAuthGatewayProvider);
      return authUser.valueOrNull?.uid ?? gateway?.currentUser?.uid;
    },
    requireOwner: true,
  );
});

final coffeeHasRecoverableV2SessionProvider = Provider<bool>((ref) {
  return ref.watch(coffeeV2SubmissionStoreProvider).load()?.isActive == true;
});

/// Whether an already-existing LEGACY (single-image) Coffee operation is
/// in flight — if so, the legacy screen must keep serving it; a fresh V2
/// capture flow is only for genuinely new Coffee readings (spec §25).
final coffeeHasLegacyPendingOperationProvider = Provider<bool>((ref) {
  final pending = ref
      .watch(readingPendingOperationStoreProvider)
      .load(ReadingType.coffee);
  return pending != null;
});

/// Session controller — must survive chamber camera pushes across all
/// three capture steps, exactly like `coffeeReadingControllerProvider`.
final coffeeV2FlowControllerProvider =
    ChangeNotifierProvider<CoffeeV2FlowController>((ref) {
      final runner = ref.watch(readingFeatureRunnerProvider);
      final stagedImages = ref.watch(coffeeV2StagedImageGatewayProvider);
      final submission = (runner != null && stagedImages != null)
          ? CoffeeV2SubmissionController(
              flow: runner.flow,
              stagedImages: stagedImages,
              store: ref.read(coffeeV2SubmissionStoreProvider),
            )
          : null;
      final controller = CoffeeV2FlowController(
        submission: submission,
        flow: runner?.flow,
        experience: ref.watch(coffeeExperienceServiceProvider),
        onAuthoritativeBalance: ref
            .read(gemWalletProvider)
            .acceptAuthoritativeBalance,
      );
      controller.boot();
      return controller;
    });
