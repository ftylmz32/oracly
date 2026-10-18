/// Shared bottom of a scene: copy, gold action, quiet skip, five dots.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/onboarding_copy.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_text_action.dart';
import 'encounter_action.dart';

class EncounterChrome extends StatelessWidget {
  const EncounterChrome({
    super.key,
    required this.scene,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onAction,
    required this.onSkip,
    this.onBack,
    this.busy = false,
    this.extra,
    this.showSkip = true,
    this.showProgress = true,
  });

  final int scene;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback? onAction;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;
  final bool busy;
  final Widget? extra;
  final bool showSkip;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x0007060E), Color(0xE607060E), Color(0xFF07060E)],
          stops: [0, 0.28, 1],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, title.isEmpty ? 4 : 28, 24, 8 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                textAlign: TextAlign.center,
                style: ReadingTypography.reflection(color: AppColors.goldLight)
                    .copyWith(fontSize: 26, height: 1.25),
              ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: ReadingTypography.body(color: AppColors.textSecondary),
              ),
            ],
            if (extra != null) ...[const SizedBox(height: 14), extra!],
            const SizedBox(height: 18),
            EncounterAction(label: action, onPressed: busy ? null : onAction),
            if (showSkip && onSkip != null) ...[
              const SizedBox(height: 4),
              OraclyTextAction(
                label: scene == 0
                    ? OnboardingCopy.exploreLabel
                    : OnboardingCopy.passLabel,
                onPressed: busy ? null : onSkip,
              ),
            ],
            if (showProgress) ...[
              const SizedBox(height: 8),
              _Dots(index: scene),
            ],
            if (onBack != null)
              Align(
                alignment: Alignment.centerLeft,
                child: OraclyTextAction(
                  label: OnboardingCopy.backLabel,
                  onPressed: busy ? null : onBack,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 5; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == index ? AppColors.gold : AppColors.gold.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
        ],
    );
  }
}
