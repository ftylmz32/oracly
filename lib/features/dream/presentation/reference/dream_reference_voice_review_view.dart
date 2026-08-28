/// Transcription review — edit before existing Dream Analysis AI.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../copy/dream_copy.dart';

class DreamReferenceVoiceReviewView extends StatelessWidget {
  const DreamReferenceVoiceReviewView({
    super.key,
    required this.controller,
    required this.onListenAgain,
    required this.onAnalyze,
    required this.onCancel,
  });

  final TextEditingController controller;
  final VoidCallback onListenAgain;
  final VoidCallback onAnalyze;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppLayout.sheetBottomInset(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DreamCopy.voiceReviewTitle,
              style: AppTextStyles.title.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: DreamCopy.narrativeHint,
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: AppColors.surface.withValues(alpha: 0.65),
                  border: _border(0.22),
                  enabledBorder: _border(0.22),
                  focusedBorder: _border(0.55),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            OraclyButton(
              text: DreamCopy.beginAnalysis,
              isExpanded: true,
              onPressed: onAnalyze,
            ),
            SizedBox(height: AppSpacing.sm),
            OraclyButton(
              text: DreamCopy.voiceListenAgain,
              type: OraclyButtonType.ghost,
              isExpanded: true,
              onPressed: onListenAgain,
            ),
            SizedBox(height: AppSpacing.sm),
            OraclyButton(
              text: 'Geri',
              type: OraclyButtonType.ghost,
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _border(double goldAlpha) {
    return OutlineInputBorder(
      borderRadius: AppRadius.md,
      borderSide: BorderSide(color: AppColors.gold.withValues(alpha: goldAlpha)),
    );
  }
}
