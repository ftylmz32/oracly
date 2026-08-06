/// OR-1000 — Ritual step navigation bar.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../theme/tarot_tokens.dart';

/// Horizontal step indicator for the tarot ritual pipeline.
class TarotNavigationBar extends StatelessWidget {
  const TarotNavigationBar({
    super.key,
    required this.currentStep,
    this.steps = _defaultSteps,
  });

  static const List<TarotFlowStep> _defaultSteps = [
    TarotFlowStep.home,
    TarotFlowStep.shuffle,
    TarotFlowStep.cardSelection,
    TarotFlowStep.reading,
  ];

  final TarotFlowStep currentStep;
  final List<TarotFlowStep> steps;

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexOf(currentStep);

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: AppBorderWidth.hairline,
                color: AppColors.gold.withValues(
                  alpha: i <= currentIndex ? 0.45 : 0.16,
                ),
              ),
            ),
          _StepDot(active: i <= currentIndex, current: i == currentIndex),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active, required this.current});

  final bool active;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.fast,
      width: current ? AppSpacing.sm + AppSpacing.xs : AppSpacing.sm,
      height: current ? AppSpacing.sm + AppSpacing.xs : AppSpacing.sm,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.goldLight : AppColors.surface,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: active ? 0.8 : 0.24),
          width: AppBorderWidth.hairline,
        ),
        boxShadow: current
            ? [
                BoxShadow(
                  color: AppColors.goldGlow.withValues(alpha: 0.45),
                  blurRadius: AppSpacing.sm,
                ),
              ]
            : null,
      ),
    );
  }
}

/// Compact step label beneath the navigation bar.
class TarotNavigationLabel extends StatelessWidget {
  const TarotNavigationLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
