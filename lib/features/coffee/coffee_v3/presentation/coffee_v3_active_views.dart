/// Coffee V3 post-create views. No route back to photo editing exists
/// here. Staging is a calm transient state (or a retry that always
/// continues the SAME operation); observation reuses the existing
/// `CoffeeLoadingView` / `CoffeeResultView` / `CoffeeErrorView` leaf
/// widgets verbatim — no second loading/result design.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../copy/coffee_copy.dart';
import '../../presentation/reference/coffee_error_view.dart';
import '../../presentation/reference/coffee_loading_view.dart';
import '../../presentation/reference/coffee_reference_tokens.dart';
import '../../presentation/reference/coffee_result_view.dart';
import '../controllers/coffee_v3_flow_controller.dart';
import '../copy/coffee_v3_copy.dart';

class CoffeeV3ActiveStagingView extends StatelessWidget {
  const CoffeeV3ActiveStagingView({super.key, required this.controller});

  final CoffeeV3FlowController controller;

  @override
  Widget build(BuildContext context) {
    final retryable = controller.stagingRetryable;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: CoffeeReferenceTokens.screenHorizontal,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!retryable)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: CircularProgressIndicator(),
              ),
            Text(
              retryable
                  ? CoffeeV3Copy.stagingConnectionLost
                  : CoffeeV3Copy.stagingInProgress,
              textAlign: TextAlign.center,
              style: ReadingTypography.secondary(),
            ),
            if (retryable) ...[
              SizedBox(height: AppSpacing.s24),
              OraclyGoldButton(
                label: CoffeeV3Copy.stagingRetry,
                onPressed: controller.retryStaging,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CoffeeV3ActiveObservingView extends StatelessWidget {
  const CoffeeV3ActiveObservingView({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final CoffeeV3FlowController controller;
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
    return CoffeeLoadingView(
      message: CoffeeCopy.analyzing,
      subtitle: CoffeeCopy.analyzingSubtitle,
      // Local hero only while the temp photo still exists; success never
      // depends on it.
      imagePath: controller.heroPath,
      onAccelerate:
          controller.canAccelerate ? controller.accelerateWaiting : null,
      accelerating: controller.accelerating,
      accelerationError: controller.accelerationError,
      accelerationCost: controller.accelerationCost,
      liveState: controller.liveState,
    );
  }
}
