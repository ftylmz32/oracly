/// Smallest-seam production switchover (Phase 2C2 §25): a genuinely new
/// Coffee reading uses the V2 guided-capture flow; an already-existing
/// legacy single-image operation keeps resolving through the untouched
/// legacy `CoffeeReferenceScreen`/`CoffeeReadingController` so no in-flight
/// legacy reading is ever stranded. Viewing a saved past reading always
/// goes through the legacy screen too (unaffected by this migration).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reading_operation/providers/reading_live_provider.dart';
import '../../presentation/reference/coffee_reference_screen.dart';
import '../../coffee_v3/presentation/coffee_v3_flow_screen.dart';
import '../../coffee_v3/providers/coffee_v3_providers.dart';
import '../../coffee_v3/services/coffee_v3_submission_store.dart';
import '../providers/coffee_v2_providers.dart';
import 'coffee_v2_flow_screen.dart';

class CoffeeV2EntryGate extends ConsumerWidget {
  const CoffeeV2EntryGate({
    super.key,
    this.savedReadingId,
    this.operationId,
  });

  final String? savedReadingId;
  final String? operationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetOperationId = operationId?.trim();
    if (targetOperationId != null && targetOperationId.isNotEmpty) {
      return CoffeeReferenceScreen(operationId: targetOperationId);
    }
    final id = savedReadingId?.trim();
    if (id != null && id.isNotEmpty) {
      return CoffeeReferenceScreen(savedReadingId: id);
    }
    // Recovery ownership always precedes new-flow selection. An ACTIVE V3
    // operation is recovered by its own flow regardless of the rollout flag
    // or UI language (flags gate NEW creation only).
    final v3State = ref.watch(coffeeV3StoredStateProvider);
    if (v3State == CoffeeV3StoredState.active) {
      return const CoffeeV3FlowScreen();
    }
    final hasV2Recovery = ref.watch(coffeeHasRecoverableV2SessionProvider);
    if (hasV2Recovery) return const CoffeeV2FlowScreen();
    final hasLegacyPending = ref.watch(coffeeHasLegacyPendingOperationProvider);
    if (hasLegacyPending) {
      return const CoffeeReferenceScreen();
    }
    // A V3 draft is never silently lost: it reopens in V3 (its create CTA
    // follows the CURRENT rollout flag + language).
    if (v3State == CoffeeV3StoredState.draft) {
      return const CoffeeV3FlowScreen();
    }
    // V2 needs live reading transport. Without it, never trap the user on
    // a blank/unavailable V2 chamber — fall back to legacy Coffee.
    final runner = ref.watch(readingFeatureRunnerProvider);
    final staged = ref.watch(coffeeV2StagedImageGatewayProvider);
    if (runner == null || staged == null) {
      return const CoffeeReferenceScreen();
    }
    // Fresh four-view V3 only when the client rollout flag is on, the UI is
    // Turkish, no V2 draft photos would be stranded, and no uninterpretable
    // V3 record is stored. Otherwise: the existing V2 route, unchanged.
    if (ref.watch(coffeeV3CreationAllowedProvider) &&
        v3State == CoffeeV3StoredState.none &&
        !ref.watch(coffeeHasV2DraftPhotosProvider)) {
      return const CoffeeV3FlowScreen();
    }
    return const CoffeeV2FlowScreen();
  }
}
