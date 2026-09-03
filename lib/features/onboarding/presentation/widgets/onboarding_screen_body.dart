/// Onboarding screen panes — intro or setup with shared busy flag.
library;

import 'package:flutter/material.dart';

import '../../../premium/models/personalization_models.dart';
import '../../data/onboarding_setup_draft.dart';
import 'onboarding_intro_pane.dart';
import 'onboarding_setup_form.dart';

class OnboardingScreenBody extends StatelessWidget {
  const OnboardingScreenBody({
    super.key,
    required this.setup,
    required this.busy,
    required this.language,
    required this.style,
    required this.draft,
    required this.onDraftChanged,
    required this.onLanguageLive,
    required this.onSkipSetup,
    required this.onContinue,
    required this.onSkipIntro,
    required this.onMeet,
  });

  final bool setup;
  final bool busy;
  final String language;
  final AiPersonality style;
  final OnboardingSetupDraft? draft;
  final ValueChanged<OnboardingSetupDraft> onDraftChanged;
  final Future<void> Function(String language) onLanguageLive;
  final void Function({required String language, required AiPersonality style})
  onSkipSetup;
  final void Function({
    required String name,
    DateTime? birthDate,
    String? birthPlace,
    required String language,
    required AiPersonality style,
  })
  onContinue;
  final VoidCallback onSkipIntro;
  final VoidCallback onMeet;

  @override
  Widget build(BuildContext context) {
    if (setup) {
      return OnboardingSetupForm(
        language: language,
        style: style,
        draft: draft,
        busy: busy,
        onDraftChanged: onDraftChanged,
        onLanguageLive: onLanguageLive,
        onSkip: onSkipSetup,
        onContinue: onContinue,
      );
    }
    return OnboardingIntroPane(busy: busy, onSkip: onSkipIntro, onMeet: onMeet);
  }
}
