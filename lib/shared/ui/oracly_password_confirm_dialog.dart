/// Password confirmation for linked-email account deletion reauth.
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

abstract final class OraclyPasswordConfirmDialog {
  OraclyPasswordConfirmDialog._();

  /// Returns the typed password, or null when cancelled. Never logs input.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String message,
    String? email,
    String? confirmLabel,
    String? cancelLabel,
  }) {
    final controller = TextEditingController();
    final confirm = confirmLabel ?? OraclyL10n.t(L10nKeys.confirm);
    final cancel = cancelLabel ?? OraclyL10n.t(L10nKeys.cancel);
    return showOraclyDialogSurface<String>(
      context,
      child: StatefulBuilder(
        builder: (dialogContext, setState) {
          final canSubmit = controller.text.isNotEmpty;
          return Padding(
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
                if (email != null && email.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.md),
                  Text(
                    email,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controller,
                  obscureText: true,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: OraclyL10n.t('auth.password_hint'),
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
                      label: confirm,
                      onPressed: canSubmit
                          ? () => Navigator.pop(
                                dialogContext,
                                controller.text,
                              )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    });
  }
}
