/// OR-1170 / TAROT V2 — clear card-count instruction.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/first_session_copy.dart';
import '../../../../../core/first_session/first_session_scope.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../copy/tarot_polish_copy.dart';
import '../tarot_flow_progress.dart';

class CardSelectionHeader extends StatelessWidget {
  const CardSelectionHeader({
    super.key,
    this.positionLabel,
    this.drawnCount = 0,
    this.requiredCount = 3,
  });

  final String? positionLabel;
  final int drawnCount;
  final int requiredCount;

  @override
  Widget build(BuildContext context) {
    final first = FirstSessionScope.of(context);
    final progress = TarotPolishCopy.cardProgress(
      drawnCount + 1,
      requiredCount,
    );
    final title = first
        ? FirstSessionCopy.cardSelectionTitleFor(isFirstSession: true)
        : TarotPolishCopy.selectCards(requiredCount);
    final subtitle = first
        ? FirstSessionCopy.cardSelectionSubtitleFor(isFirstSession: true)
        : (positionLabel == null || positionLabel!.isEmpty
            ? progress
            : '$progress · $positionLabel');

    return Column(
      children: [
        const TarotFlowProgress(step: TarotRitualStep.selection),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  height: 1.35,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.25,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
