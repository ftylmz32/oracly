/// OR-1120 — Consistent snackbar presentation.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

abstract final class OraclySnackBar {
  OraclySnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.22),
          ),
        ),
        action: action,
        duration: duration,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message);
  }

  static void error(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      duration: const Duration(seconds: 4),
      action: action,
    );
  }
}
