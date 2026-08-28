/// OR-1050+ — Post-reveal metadata with staggered fade-in.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../core/widgets/oracly_signature_motifs.dart';
import 'card_reveal_spread.dart';
import 'reveal_result_panel_chrome.dart';

class RevealResultPanel extends StatelessWidget {
  const RevealResultPanel({
    super.key,
    required this.data,
    required this.nameOpacity,
    required this.subtitleOpacity,
    required this.badgeOpacity,
    required this.buttonOpacity,
    required this.buttonSlide,
    required this.onContinue,
    this.completionHint,
  });

  final RevealCardData data;
  final double nameOpacity;
  final double subtitleOpacity;
  final double badgeOpacity;
  final double buttonOpacity;
  final double buttonSlide;
  final VoidCallback onContinue;
  final String? completionHint;

  @override
  Widget build(BuildContext context) {
    final nameSlide = (1 - nameOpacity) * 16;
    final hint = completionHint?.trim();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OraclySignatureDivider(compact: true),
          Transform.translate(
            offset: Offset(0, nameSlide),
            child: Opacity(
              opacity: nameOpacity.clamp(0.0, 1.0),
              child: Text(
                data.displayName,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Opacity(
            opacity: subtitleOpacity.clamp(0.0, 1.0),
            child: Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: ReadingTypography.body(color: AppColors.textSecondary),
            ),
          ),
          if (hint != null && hint.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Opacity(
              opacity: badgeOpacity.clamp(0.0, 1.0),
              child: Text(
                hint,
                textAlign: TextAlign.center,
                style: ReadingTypography.body(
                  color: AppColors.gold.withValues(alpha: 0.78),
                ),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.md),
          Opacity(
            opacity: badgeOpacity.clamp(0.0, 1.0),
            child: RevealRarityChip(
              label: data.rarityLabel,
              color: data.rarityColor,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Transform.translate(
            offset: Offset(0, (1 - buttonSlide) * 28),
            child: Opacity(
              opacity: buttonOpacity.clamp(0.0, 1.0),
              child: RevealContinueCta(onPressed: onContinue),
            ),
          ),
        ],
      ),
    );
  }
}
