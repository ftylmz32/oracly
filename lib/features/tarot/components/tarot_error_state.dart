/// OR-1000 — Tarot error state component.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/copy/resilience_copy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'tarot_button.dart';

/// Recoverable error surface for tarot flows.
class TarotErrorState extends StatelessWidget {
  const TarotErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenHorizontal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: AppSpacing.xxl, color: AppColors.error),
            SizedBox(height: AppSpacing.md),
            Text(
              ResilienceCopy.errorTitle,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: AppSpacing.lg),
              Semantics(
                button: true,
                label: ResilienceCopy.retryAction,
                child: TarotSecondaryButton(
                  label: ResilienceCopy.retryAction,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
