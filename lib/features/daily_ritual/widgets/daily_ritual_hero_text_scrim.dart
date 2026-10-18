/// Lower scrim — copy sits on the foreground; sky stays open.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Smooth dark-to-transparent gradient; no hard panel edge.
class DailyRitualHeroTextScrim extends StatelessWidget {
  const DailyRitualHeroTextScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.background.withValues(alpha: 0.84),
            AppColors.background.withValues(alpha: 0.50),
            AppColors.background.withValues(alpha: 0.08),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.34, 0.58, 0.84],
        ),
      ),
    );
  }
}
