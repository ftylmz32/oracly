/// Reveal panel chrome — chip + continue CTA.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/first_session_copy.dart';
import '../../../../../core/copy/resilience_copy.dart';
import '../../../../../core/first_session/first_session_scope.dart';
import '../../../../../core/security/ai_error_sanitizer.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../shared/widgets/oracly_button.dart';
import '../../../../../shared/widgets/oracly_text_action.dart';

class RevealRarityChip extends StatelessWidget {
  const RevealRarityChip({super.key, required this.label, required this.color});

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
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14),
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
  const RevealContinueCta({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OraclyButton(
      text: FirstSessionScope.of(context)
          ? FirstSessionCopy.revealContinue
          : FirstSessionCopy.revealContinueDefault,
      onPressed: onPressed,
      isExpanded: true,
      isLoading: isLoading,
      size: OraclyButtonSize.large,
    );
  }
}

/// Compact recoverable notice — cards stay on screen.
class RevealAdvanceError extends StatelessWidget {
  const RevealAdvanceError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AiErrorSanitizer.guard(message),
          textAlign: TextAlign.center,
          style: ReadingTypography.bodySmall(color: AppColors.textSecondary),
        ),
        if (onRetry != null) ...[
          SizedBox(height: AppSpacing.sm),
          OraclyTextAction(
            label: ResilienceCopy.retryAction,
            emphasized: true,
            onPressed: onRetry,
          ),
        ],
      ],
    );
  }
}
