/// OR-1110 — AI typing indicator with animated dots.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import 'oracle_avatar.dart';

class AITypingIndicator extends StatefulWidget {
  const AITypingIndicator({super.key});

  @override
  State<AITypingIndicator> createState() => _AITypingIndicatorState();
}

class _AITypingIndicatorState extends State<AITypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(
      vsync: this,
      duration: CraftsmanshipRhythm.pulse,
    )..repeat();
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const OracleAvatar(size: 28, showGlow: false),
        SizedBox(width: AppSpacing.sm),
        AnimatedBuilder(
          animation: _dots,
          builder: (context, _) {
            return Row(
              children: List.generate(3, (i) {
                final phase = (_dots.value + i * 0.2) % 1.0;
                final opacity = 0.3 + (phase < 0.5 ? phase : 1 - phase) * 1.4;
                return Padding(
                  padding: EdgeInsets.only(right: AppSpacing.xs),
                  child: Opacity(
                    opacity: opacity.clamp(0.3, 1.0),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
