/// Confirm / info dialog bodies for OraclyDialog.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/oracly_gold_button.dart';
import '../widgets/oracly_text_action.dart';
import 'oracly_dialog_actions.dart';
import 'oracly_dialog_surface.dart';

Future<bool?> showOraclyConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Onayla',
  String cancelLabel = 'İptal',
  bool destructive = false,
}) {
  return showOraclyDialogSurface<bool>(
    context,
    child: Builder(
      builder: (dialogContext) => Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.goldLight,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            OraclyDialogActions(
              children: [
                OraclyTextAction(
                  label: cancelLabel,
                  onPressed: () => Navigator.pop(dialogContext, false),
                ),
                if (destructive)
                  OraclyTextAction(
                    label: confirmLabel,
                    emphasized: true,
                    destructive: true,
                    onPressed: () => Navigator.pop(dialogContext, true),
                  )
                else
                  OraclyGoldButton(
                    label: confirmLabel,
                    onPressed: () => Navigator.pop(dialogContext, true),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showOraclyInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'Tamam',
}) {
  return showOraclyDialogSurface<void>(
    context,
    child: Builder(
      builder: (dialogContext) => Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.goldLight,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            OraclyDialogActions(
              children: [
                OraclyGoldButton(
                  label: buttonLabel,
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
