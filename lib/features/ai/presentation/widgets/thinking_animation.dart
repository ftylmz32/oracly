/// OR-1110 — Thinking animation for AI processing state.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/app_text_styles.dart';

class ThinkingAnimation extends StatefulWidget {
  const ThinkingAnimation({
    super.key,
    this.label = 'OR düşünüyor...',
  });

  final String label;

  @override
  State<ThinkingAnimation> createState() => _ThinkingAnimationState();
}

class _ThinkingAnimationState extends State<ThinkingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: CraftsmanshipRhythm.think,
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = sin(_pulse.value * pi * 2);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.5 + t.abs() * 0.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldGlow.withValues(alpha: 0.3 + t.abs() * 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              widget.label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
