/// OR-1050+ — Post-reveal metadata with staggered fade-in.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/first_session_copy.dart';
import '../../../../../core/first_session/first_session_scope.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../shared/widgets/oracly_button.dart';
import '../../../../../core/widgets/oracly_signature_motifs.dart';
import 'card_reveal_spread.dart';

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
  });

  final RevealCardData data;
  final double nameOpacity;
  final double subtitleOpacity;
  final double badgeOpacity;
  final double buttonOpacity;
  final double buttonSlide;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final nameSlide = (1 - nameOpacity) * 16;

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
              style: ReadingTypography.body(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Opacity(
            opacity: badgeOpacity.clamp(0.0, 1.0),
            child: _RarityChip(
              label: data.rarityLabel,
              color: data.rarityColor,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Transform.translate(
            offset: Offset(0, (1 - buttonSlide) * 28),
            child: Opacity(
              opacity: buttonOpacity.clamp(0.0, 1.0),
              child: _RevealCta(onPressed: onContinue),
            ),
          ),
        ],
      ),
    );
  }
}

class _RarityChip extends StatelessWidget {
  const _RarityChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.round,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.55),
          width: AppBorderWidth.hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 14,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.goldLight,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _RevealCta extends StatelessWidget {
  const _RevealCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OraclyButton(
      text: FirstSessionScope.of(context)
          ? FirstSessionCopy.revealContinue
          : FirstSessionCopy.revealContinueDefault,
      onPressed: onPressed,
      isExpanded: true,
      size: OraclyButtonSize.large,
    );
  }
}
