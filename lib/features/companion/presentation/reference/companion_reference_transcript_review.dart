/// Low-confidence transcript review - edit in composer or listen again.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/companion_copy.dart';

class CompanionReferenceTranscriptReview extends StatelessWidget {
  const CompanionReferenceTranscriptReview({
    super.key,
    required this.visible,
    required this.onRetry,
    required this.onConfirm,
  });

  final bool visible;
  final VoidCallback onRetry;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final palette = AppColors.of(context);
    return Semantics(
      liveRegion: true,
      label: CompanionCopy.voiceReviewHint,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              CompanionCopy.voiceReviewHint,
              style: ReadingTypography.bodySmall(
                color: palette.textSecondary
                    .withValues(alpha: OraclyA11y.secondaryCream),
              ),
            ),
            SizedBox(height: AppSpacing.s8),
            Row(
              children: [
                Expanded(
                  child: _Action(
                    label: CompanionCopy.voiceReviewRetry,
                    onTap: onRetry,
                  ),
                ),
                SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: _Action(
                    label: CompanionCopy.voiceReviewSend,
                    onTap: onConfirm,
                    emphasize: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.onTap,
    this.emphasize = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: OraclyPressable(
        onTap: onTap,
        child: OraclyA11y.ensureMinTouch(
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: emphasize
                  ? palette.gold.withValues(alpha: 0.18)
                  : palette.surface.withValues(alpha: 0.45),
              border: Border.all(
                color: palette.gold.withValues(alpha: emphasize ? 0.55 : 0.28),
              ),
            ),
            child: Text(
              label,
              style: ReadingTypography.sectionLabel(
                fontSize: 11,
                color: emphasize ? palette.goldLight : palette.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
