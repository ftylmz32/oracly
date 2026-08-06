/// OR-030 — Tarot section heading with decorative lines.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'tarot_decorative_line.dart';

class TarotSectionHeading extends StatelessWidget {
  const TarotSectionHeading({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const TarotDecorativeLine(width: 36),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const TarotDecorativeLine(width: 36),
      ],
    );
  }
}
