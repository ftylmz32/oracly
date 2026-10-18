/// Five windows in the observatory. The arches stay visible.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/onboarding_copy.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'encounter_chrome.dart';
import 'encounter_hall_plate.dart';
import 'encounter_interest_windows.dart';

class EncounterInterestScene extends StatelessWidget {
  const EncounterInterestScene({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onContinue,
    required this.onSkip,
    required this.onBack,
    this.busy = false,
  });

  final List<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final line = OnboardingCopy.interestLines(selected);
    return Stack(
      fit: StackFit.expand,
      children: [
        const EncounterHallPlate(),
        IgnorePointer(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: selected.isEmpty ? 0 : 1,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9,
                  colors: [Color(0x33E8C872), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gap = (constraints.maxHeight * 0.08).clamp(12.0, 72.0);
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Text(
                          OnboardingCopy.interestTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.goldLight,
                            height: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: gap),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: EncounterInterestWindows(
                          width: constraints.maxWidth - 32,
                          selected: selected,
                          onToggle: onToggle,
                        ),
                      ),
                      EncounterChrome(
                        scene: 2,
                        title: '',
                        subtitle: line,
                        action: OnboardingCopy.continueLabel,
                        onAction: onContinue,
                        onSkip: onSkip,
                        onBack: onBack,
                        busy: busy,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
