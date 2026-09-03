/// Custom intention dialog for the table.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

Future<String?> showTarotCustomIntentDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF120C1C),
      title: Text(
        OraclyL10n.t('tarot.ritual.intention_title'),
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.gold),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(OraclyL10n.t(L10nKeys.dismiss)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(OraclyL10n.t(L10nKeys.ok)),
        ),
      ],
    ),
  );
}
