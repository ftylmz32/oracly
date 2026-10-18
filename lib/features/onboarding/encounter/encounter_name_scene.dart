/// The question lives in the sky. The name is written on the plate.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/onboarding_copy.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/theme/reading_typography.dart';
import 'encounter_chrome.dart';
import 'encounter_name_plate.dart';

class EncounterNameScene extends StatelessWidget {
  const EncounterNameScene({
    super.key,
    required this.controller,
    required this.onContinue,
    required this.onSkip,
    required this.onBack,
    this.busy = false,
    this.showProgress = true,
  });

  final TextEditingController controller;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final bool busy;

  /// Five-scene dots; off when the name is asked from Home.
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final keyboard = View.of(context).viewInsets.bottom > 0;
    return Stack(
      fit: StackFit.expand,
      children: [
        EncounterNamePlate(controller: controller),
        if (!keyboard)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                child: Column(
                  children: [
                    Text(
                      OnboardingCopy.nameTitle,
                      textAlign: TextAlign.center,
                      style: ReadingTypography.reflection(color: AppColors.goldLight)
                          .copyWith(fontSize: 24, height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      OnboardingCopy.nameHintLine,
                      textAlign: TextAlign.center,
                      style: ReadingTypography.body(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final name = controller.text.trim();
              return EncounterChrome(
                scene: 1,
                title: '',
                subtitle: name.isEmpty ? '' : OnboardingCopy.nameMet(name),
                action: OnboardingCopy.continueLabel,
                onAction: onContinue,
                onSkip: keyboard ? null : onSkip,
                onBack: keyboard ? null : onBack,
                showSkip: !keyboard,
                showProgress: showProgress && !keyboard,
                busy: busy,
              );
            },
          ),
        ),
      ],
    );
  }
}
