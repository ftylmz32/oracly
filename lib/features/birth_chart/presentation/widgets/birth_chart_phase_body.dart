/// Phase switcher for Birth Chart — form, loading, result, recovery.
library;

import 'package:flutter/material.dart';

import '../../controllers/birth_chart_controller.dart';
import '../../copy/birth_chart_copy.dart';
import 'birth_chart_onboarding_view.dart';
import 'birth_chart_phase_views.dart';
import 'birth_chart_result_view.dart';

class BirthChartPhaseBody extends StatelessWidget {
  const BirthChartPhaseBody({super.key, required this.controller});

  final BirthChartController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.phase) {
      BirthChartPhase.onboarding when controller.isInitializing =>
        BirthChartLoadingView(
          key: ValueKey('initializing'),
          message: BirthChartCopy.preparingJourney,
        ),
      BirthChartPhase.onboarding => BirthChartOnboardingView(
          key: ValueKey(
            '${controller.onboardingProfileHint?.birthPlace}-'
            '${controller.onboardingProfileHint?.birthDate}',
          ),
          initialProfile: controller.onboardingProfileHint,
          isEditing: controller.isEditing,
          onSubmit: controller.generate,
          onCancel: controller.isEditing ? controller.cancelEdit : null,
        ),
      BirthChartPhase.generating => BirthChartLoadingView(
          key: ValueKey('generating'),
          message: BirthChartCopy.generating,
        ),
      BirthChartPhase.journey when controller.chart == null =>
        BirthChartIncompleteView(
          key: const ValueKey('journey-incomplete'),
          onRecover: controller.recoverJourney,
          onStartOver: controller.restartOnboarding,
          onRegenerate: controller.regenerateFromSavedProfile,
          onClearSaved: controller.clearSavedAndRestart,
          canRegenerate: controller.onboardingProfileHint != null,
        ),
      BirthChartPhase.journey || BirthChartPhase.complete =>
        BirthChartResultView(
          key: ValueKey('result-${controller.chart?.id}'),
          chart: controller.chart!,
          closingMessage: BirthChartCopy.closingNote,
          onUpdateInfo: controller.beginEdit,
        ),
      BirthChartPhase.error => BirthChartErrorView(
          key: const ValueKey('error'),
          message: controller.errorMessage ?? BirthChartCopy.generateFailed,
          onRetry: () {
            if (controller.chart != null) {
              controller.recoverJourney();
            } else if (controller.onboardingProfileHint != null) {
              controller.regenerateFromSavedProfile();
            }
          },
          onBack: controller.restartOnboarding,
        ),
    };
  }
}
