import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DailyInsightSection extends StatelessWidget {
  const DailyInsightSection({super.key});

  static const _energyPercent = 82;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
      child: Column(
        children: [
          Text(
            "Today's Energy",
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.44),
              letterSpacing: 1.6,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$_energyPercent%',
            textAlign: TextAlign.center,
            style: AppTextStyles.hero.copyWith(
              fontSize: 60,
              height: 0.92,
              fontWeight: FontWeight.w200,
              letterSpacing: -3.2,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: AppColors.gold.withValues(alpha: 0.94),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'High Spiritual Alignment',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle.copyWith(
              fontSize: 14,
              height: 1.65,
              letterSpacing: 0.35,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.46),
            ),
          ),
        ],
      ),
    );
  }
}
