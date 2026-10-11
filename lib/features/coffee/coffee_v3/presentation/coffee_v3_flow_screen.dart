/// Coffee V3 three-photo top-level screen. Body-switches on
/// `CoffeeV3FlowController.stage` inside the SAME chamber chrome
/// (`CoffeeLandingChamber`) Coffee already uses. Every mutation persists
/// through `CoffeeV3SubmissionStore` immediately, so leaving at any DRAFT
/// point never loses a confirmed photo; once ACTIVE there is no route back
/// to editing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/chamber_waiting_stage.dart';
import '../../../../shared/navigation/oracly_navigation.dart';
import '../../../personal_discovery/services/personal_discovery_refresh.dart';
import '../../coffee_v2/presentation/coffee_v2_flow_screen.dart';
import '../../copy/coffee_copy.dart';
import '../../presentation/reference/coffee_error_view.dart';
import '../../presentation/reference/coffee_landing_chamber.dart';
import '../../presentation/reference/coffee_reference_screen.dart';
import '../models/coffee_v3_flow_stage.dart';
import '../providers/coffee_v3_providers.dart';
import 'coffee_v3_active_views.dart';
import 'coffee_v3_final_review_view.dart';
import 'coffee_v3_intro_view.dart';
import 'coffee_v3_preview_view.dart';
import 'coffee_v3_step_view.dart';

class CoffeeV3FlowScreen extends ConsumerStatefulWidget {
  const CoffeeV3FlowScreen({super.key});

  @override
  ConsumerState<CoffeeV3FlowScreen> createState() => _CoffeeV3FlowScreenState();
}

class _CoffeeV3FlowScreenState extends ConsumerState<CoffeeV3FlowScreen> {
  String? _journalRefreshedFor;

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(coffeeV3FlowControllerProvider);
    ref.listen(coffeeV3FlowControllerProvider, (_, next) {
      final shownId = next.reading?.id;
      if (shownId != null && shownId != _journalRefreshedFor) {
        _journalRefreshedFor = shownId;
        PersonalDiscoveryRefresh.invalidate(ref);
      }
    });
    final stage = controller.stage;
    // Nothing V3-owned and NEW V3 creation not allowed: the default route
    // (Coffee V2) owns this visit — never a dead-end V3 chamber.
    if (stage == CoffeeV3FlowStage.exitToDefault) {
      return const CoffeeV2FlowScreen();
    }
    return CoffeeLandingChamber(
      onBack: () => _handleBack(context),
      child: switch (stage) {
        CoffeeV3FlowStage.booting ||
        CoffeeV3FlowStage.exitToDefault =>
          ChamberWaitingStage(message: CoffeeCopy.analyzing),
        CoffeeV3FlowStage.unavailable => CoffeeErrorView(
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
        CoffeeV3FlowStage.intro => CoffeeV3IntroView(
            onStart: controller.dismissIntro,
          ),
        CoffeeV3FlowStage.step => CoffeeV3StepView(
            controller: controller,
            slot: controller.currentStepSlot,
          ),
        CoffeeV3FlowStage.preview => CoffeeV3PreviewView(
            controller: controller,
          ),
        CoffeeV3FlowStage.finalReview => CoffeeV3FinalReviewView(
            controller: controller,
          ),
        CoffeeV3FlowStage.activeStaging => CoffeeV3ActiveStagingView(
            controller: controller,
          ),
        CoffeeV3FlowStage.activeObserving => CoffeeV3ActiveObservingView(
            controller: controller,
            onBack: () => _handleBack(context),
          ),
      },
    );
  }
}
