/// The gate, completed. The name is spoken once.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/copy/onboarding_copy.dart';
import '../data/onboarding_setup_draft.dart';
import 'encounter_chrome.dart';
import 'encounter_plate.dart';

class EncounterWelcomeScene extends StatelessWidget {
  const EncounterWelcomeScene({
    super.key,
    required this.draft,
    required this.onEnter,
    required this.onBack,
    this.busy = false,
  });

  final OnboardingSetupDraft draft;
  final VoidCallback onEnter;
  final VoidCallback onBack;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final name = draft.name?.trim() ?? '';
    return Stack(
      fit: StackFit.expand,
      children: [
        const EncounterPlate(asset: AppAssets.encounterWelcome),
        Align(
          alignment: Alignment.bottomCenter,
          child: EncounterChrome(
            scene: 4,
            showSkip: false,
            title: OnboardingCopy.welcomeTitle(name),
            subtitle: OnboardingCopy.welcomeLines(draft.interests),
            action: OnboardingCopy.enterLabel,
            onAction: onEnter,
            onSkip: onEnter,
            onBack: onBack,
            busy: busy,
          ),
        ),
      ],
    );
  }
}
