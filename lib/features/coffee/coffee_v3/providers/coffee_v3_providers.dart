/// Coffee V3 four-view providers. Additive only — reuses the SAME
/// `readingFeatureRunnerProvider` (ReadingLiveFlow), staged-image gateway,
/// `coffeeExperienceServiceProvider`, `gemWalletProvider`,
/// `localStorageProvider` and Firebase owner resolution as Coffee V2. No
/// second network sender, auth stack or gem economy.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/providers/backend_providers.dart'
    show firebaseAuthGatewayProvider, firebaseAuthUserProvider;
import '../../../gems/providers/gem_providers.dart';
import '../../../reading_operation/providers/reading_live_provider.dart';
import '../../coffee_v2/providers/coffee_v2_providers.dart';
import '../../providers/coffee_providers.dart';
import '../controllers/coffee_v3_flow_controller.dart';
import '../services/coffee_v3_creation_gate.dart';
import '../services/coffee_v3_submission_controller.dart';
import '../services/coffee_v3_submission_store.dart';

final coffeeV3SubmissionStoreProvider = Provider<CoffeeV3SubmissionStore>((
  ref,
) {
  // Stable instance; owner resolved at read/write time (same as V2).
  return CoffeeV3SubmissionStore(
    ref.watch(localStorageProvider),
    ownerResolver: () {
      final authUser = ref.read(firebaseAuthUserProvider);
      final gateway = ref.read(firebaseAuthGatewayProvider);
      return authUser.valueOrNull?.uid ?? gateway?.currentUser?.uid;
    },
    requireOwner: true,
  );
});

/// What V3 state exists locally for the current owner (entry routing).
/// autoDispose: re-read on every Coffee entry, never a stale cache.
final coffeeV3StoredStateProvider = Provider.autoDispose<CoffeeV3StoredState>((
  ref,
) {
  return ref.watch(coffeeV3SubmissionStoreProvider).inspect();
});

/// Whether a NEW V3 capture may start now (rollout flag + Turkish UI).
final coffeeV3CreationAllowedProvider = Provider.autoDispose<bool>((ref) {
  return CoffeeV3CreationGate.creationAllowed;
});

/// A Coffee V2 DRAFT that already holds photos — never stranded by a newly
/// enabled V3 rollout.
final coffeeHasV2DraftPhotosProvider = Provider.autoDispose<bool>((ref) {
  final record = ref.watch(coffeeV2SubmissionStoreProvider).load();
  return record != null &&
      record.isDraft &&
      record.slots.values.any((slot) => slot.asset != null);
});

final coffeeV3FlowControllerProvider =
    ChangeNotifierProvider<CoffeeV3FlowController>((ref) {
      final runner = ref.watch(readingFeatureRunnerProvider);
      final stagedImages = ref.watch(coffeeV2StagedImageGatewayProvider);
      final submission = (runner != null && stagedImages != null)
          ? CoffeeV3SubmissionController(
              flow: runner.flow,
              stagedImages: stagedImages,
              store: ref.read(coffeeV3SubmissionStoreProvider),
            )
          : null;
      final controller = CoffeeV3FlowController(
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
