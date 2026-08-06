/// OR-1170 — Card selection ritual header copy.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/first_session_copy.dart';
import '../../../../../core/first_session/first_session_scope.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class CardSelectionHeader extends StatelessWidget {
  const CardSelectionHeader({
    super.key,
    this.positionLabel,
    this.progressLabel,
  });

  final String? positionLabel;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    final isFirstSession = FirstSessionScope.of(context);
    final defaultTitle = FirstSessionCopy.cardSelectionTitleFor(
      isFirstSession: isFirstSession,
    );
    final title = positionLabel == null
        ? defaultTitle
        : '$positionLabel konumuna kart seç.';
    final subtitle = progressLabel == null || progressLabel!.isEmpty
        ? FirstSessionCopy.cardSelectionSubtitleFor(isFirstSession: isFirstSession)
        : 'Kart $progressLabel · ${FirstSessionCopy.cardSelectionSubtitleFor(isFirstSession: isFirstSession)}';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
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
    );
  }
}
