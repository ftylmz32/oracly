/// Coffee V2 post-staging wait/live/result experience (Phase 2C2 §17/§27).
/// Reuses the EXISTING `CoffeeLoadingView`/`CoffeeResultView`/
/// `CoffeeErrorView` widgets verbatim — this is not a second loading/result
/// system, only a different controller (`CoffeeV2FlowController`) feeding
/// the same leaf widgets the exact same props legacy Coffee already does.
library;

import 'package:flutter/material.dart';

import '../controllers/coffee_v2_flow_controller.dart';
import '../../copy/coffee_copy.dart';
import '../models/coffee_v2_photo_slot.dart' as v2_slot;
import '../../presentation/reference/coffee_error_view.dart';
import '../../presentation/reference/coffee_loading_view.dart';
import '../../presentation/reference/coffee_result_view.dart';

class CoffeeV2ActiveObservingView extends StatelessWidget {
  const CoffeeV2ActiveObservingView({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final CoffeeV2FlowController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final reading = controller.reading;
    if (reading != null) {
      return CoffeeResultView(
        reading: reading,
        onNewCup: controller.resetToFreshDraft,
      );
    }
    final error = controller.observeError;
    if (error != null) {
      return CoffeeErrorView(
        message: error,
        onRetry: controller.resetToFreshDraft,
        onBack: onBack,
      );
    }
    final heroPath = controller.submission
        ?.assetFor(v2_slot.CoffeeV2PhotoSlot.cupPrimary)
        ?.path;
    return CoffeeLoadingView(
      message: CoffeeCopy.analyzing,
      subtitle: CoffeeCopy.analyzingSubtitle,
      imagePath: heroPath,
      onAccelerate: controller.canAccelerate
          ? controller.accelerateWaiting
          : null,
      accelerating: controller.accelerating,
      accelerationError: controller.accelerationError,
      accelerationCost: controller.accelerationCost,
      liveState: controller.liveState,
    );
  }
}
