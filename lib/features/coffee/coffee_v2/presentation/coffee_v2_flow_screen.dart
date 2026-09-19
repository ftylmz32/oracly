/// Coffee V2 guided-capture top-level screen (Phase 2C2). Body-switches on
/// `CoffeeV2FlowController.stage` inside the SAME chamber chrome
/// (`CoffeeLandingChamber`) legacy Coffee uses — no new visual shell.
///
/// Back navigation here is intentionally the platform default (no custom
/// `PopScope`): every mutation this flow makes is persisted through
/// `CoffeeV2SubmissionStore` immediately, so leaving the screen at any
/// point in DRAFT never silently loses a confirmed photo, and once ACTIVE
/// there is no "back to editing" affordance to guard against in the first
/// place (spec §18/§19).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/chamber_waiting_stage.dart';
import '../../../../shared/navigation/oracly_navigation.dart';
import '../../copy/coffee_copy.dart';
import '../../presentation/reference/coffee_error_view.dart';
import '../../presentation/reference/coffee_landing_chamber.dart';
import '../../presentation/reference/coffee_reference_screen.dart';
import '../models/coffee_v2_flow_stage.dart';
import '../providers/coffee_v2_providers.dart';
import 'coffee_v2_active_observing_view.dart';
import 'coffee_v2_active_staging_view.dart';
import 'coffee_v2_final_review_view.dart';
import 'coffee_v2_intro_view.dart';
import 'coffee_v2_preview_view.dart';
import 'coffee_v2_step_view.dart';

class CoffeeV2FlowScreen extends ConsumerWidget {
  const CoffeeV2FlowScreen({super.key});

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(coffeeV2FlowControllerProvider);
    return CoffeeLandingChamber(
      onBack: () => _handleBack(context),
      child: switch (controller.stage) {
        CoffeeV2FlowStage.booting => ChamberWaitingStage(
            message: CoffeeCopy.analyzing,
          ),
        CoffeeV2FlowStage.unavailable => CoffeeErrorView(
            message: CoffeeCopy.analysisUnavailable,
            onRetry: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const CoffeeReferenceScreen(),
                ),
              );
            },
            onBack: () => _handleBack(context),
          ),
        CoffeeV2FlowStage.intro => CoffeeV2IntroView(
            onStart: controller.dismissIntro,
          ),
        CoffeeV2FlowStage.step => CoffeeV2StepView(
            controller: controller,
            slot: controller.currentStepSlot,
          ),
        CoffeeV2FlowStage.preview => CoffeeV2PreviewView(
            controller: controller,
          ),
        CoffeeV2FlowStage.finalReview => CoffeeV2FinalReviewView(
            controller: controller,
          ),
        CoffeeV2FlowStage.activeStaging => CoffeeV2ActiveStagingView(
            controller: controller,
          ),
        CoffeeV2FlowStage.activeObserving => CoffeeV2ActiveObservingView(
            controller: controller,
            onBack: () => _handleBack(context),
          ),
      },
    );
  }
}
