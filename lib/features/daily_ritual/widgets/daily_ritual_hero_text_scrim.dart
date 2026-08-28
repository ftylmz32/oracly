/// Left atmospheric scrim — text readability over hero artwork.
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
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.background.withValues(alpha: 0.64),
            AppColors.background.withValues(alpha: 0.34),
            AppColors.background.withValues(alpha: 0.10),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.28, 0.52, 0.74],
        ),
      ),
    );
  }
}
