/// Confirm / info dialog bodies for OraclyDialog.
library;

import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
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
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) {
  final confirm = confirmLabel ?? OraclyL10n.t(L10nKeys.confirm);
  final cancel = cancelLabel ?? OraclyL10n.t(L10nKeys.cancel);
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
                  label: cancel,
                  onPressed: () => Navigator.pop(dialogContext, false),
                ),
                if (destructive)
                  OraclyTextAction(
                    label: confirm,
                    emphasized: true,
                    destructive: true,
                    onPressed: () => Navigator.pop(dialogContext, true),
                  )
                else
                  OraclyGoldButton(
                    label: confirm,
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
  String? buttonLabel,
}) {
  final ok = buttonLabel ?? OraclyL10n.t(L10nKeys.ok);
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
                  label: ok,
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
