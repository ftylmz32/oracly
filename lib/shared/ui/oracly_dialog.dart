/// OR-1120 / EPIC-025 — Consistent dialog presentation with luxury motion.
library;

import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/oracly_gold_button.dart';
import '../widgets/oracly_text_action.dart';
import 'oracly_dialog_actions.dart';
import 'oracly_dialog_alerts.dart';
import 'oracly_dialog_surface.dart';

abstract final class OraclyDialog {
  OraclyDialog._();

  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) {
    return showOraclyConfirmDialog(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel ?? OraclyL10n.t(L10nKeys.confirm),
      cancelLabel: cancelLabel ?? OraclyL10n.t(L10nKeys.cancel),
      destructive: destructive,
    );
  }

  static Future<String?> prompt(
    BuildContext context, {
    required String title,
    required String hint,
    String initial = '',
    String? confirmLabel,
    String? cancelLabel,
  }) {
    final controller = TextEditingController(text: initial);
    final save = confirmLabel ?? OraclyL10n.t(L10nKeys.save);
    final cancel = cancelLabel ?? OraclyL10n.t(L10nKeys.cancel);
    return showOraclyDialogSurface<String>(
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
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                autofocus: true,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              OraclyDialogActions(
                children: [
                  OraclyTextAction(
                    label: cancel,
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                  OraclyGoldButton(
                    label: save,
                    onPressed: () => Navigator.pop(
                      dialogContext,
                      controller.text.trim(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      // After the route is gone — never dispose mid-frame under TextField.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    });
  }

  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonLabel,
  }) {
    return showOraclyInfoDialog(
      context,
      title: title,
      message: message,
      buttonLabel: buttonLabel ?? OraclyL10n.t(L10nKeys.ok),
    );
  }
}
