/// Gate and name — the opening of the same encounter.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/copy/onboarding_copy.dart';
import 'encounter_chrome.dart';
import 'encounter_stage.dart';

class EncounterGateScene extends StatelessWidget {
  const EncounterGateScene({
    super.key,
    required this.onMeet,
    required this.onSkip,
    this.busy = false,
  });

  final VoidCallback onMeet;
  final VoidCallback onSkip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return EncounterStage(
      asset: AppAssets.encounterGate,
      child: EncounterChrome(
            scene: 0,
            title: OnboardingCopy.gateTitle,
            subtitle: OnboardingCopy.gateSubtitle,
            action: OnboardingCopy.meetLabel,
            onAction: onMeet,
            onSkip: onSkip,
            busy: busy,
          ),
    );
  }
}
