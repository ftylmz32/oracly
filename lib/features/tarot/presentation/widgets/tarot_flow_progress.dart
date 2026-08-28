/// TAROT V2 — quiet ritual step: Niyet → Kart Seçimi → Açılım → Yorum.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../copy/tarot_polish_copy.dart';

enum TarotRitualStep { intention, selection, reveal, reading }

class TarotFlowProgress extends StatelessWidget {
  const TarotFlowProgress({super.key, required this.step});

  final TarotRitualStep step;

  static List<String> get _labels => [
        TarotPolishCopy.stepIntention,
        TarotPolishCopy.stepSelection,
        TarotPolishCopy.stepReveal,
        TarotPolishCopy.stepReading,
      ];

  @override
  Widget build(BuildContext context) {
    final active = step.index;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _labels.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    '→',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textHint.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              Text(
                _labels[i],
                style: AppTextStyles.labelSmall.copyWith(
                  color: i == active
                      ? AppColors.goldLight
                      : i < active
                          ? AppColors.gold.withValues(alpha: 0.62)
                          : AppColors.textHint.withValues(alpha: 0.55),
                  fontWeight: i == active ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
