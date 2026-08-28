/// Reveal panel chrome — chip + continue CTA.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/first_session_copy.dart';
import '../../../../../core/first_session/first_session_scope.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/oracly_button.dart';

class RevealRarityChip extends StatelessWidget {
  const RevealRarityChip({
    super.key,
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

class RevealContinueCta extends StatelessWidget {
  const RevealContinueCta({super.key, required this.onPressed});

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
