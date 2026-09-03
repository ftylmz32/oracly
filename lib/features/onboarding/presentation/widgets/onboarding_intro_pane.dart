/// Intro pane: skip + meet — no permissions.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/onboarding_copy.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../../../shared/widgets/oracly_text_action.dart';
import 'onboarding_page.dart';

class OnboardingIntroPane extends StatelessWidget {
  const OnboardingIntroPane({
    super.key,
    required this.onSkip,
    required this.onMeet,
    this.busy = false,
  });

  final VoidCallback onSkip;
  final VoidCallback onMeet;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OraclyTextAction(
            label: OnboardingCopy.skip,
            onPressed: busy ? null : onSkip,
          ),
        ),
        const Expanded(child: OnboardingPage()),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: OraclyButton(
            text: OnboardingCopy.meetLabel,
            isExpanded: true,
            icon: Icons.arrow_forward_rounded,
            isLoading: busy,
            enabled: !busy,
            onPressed: busy ? null : onMeet,
          ),
        ),
      ],
    );
  }
}
