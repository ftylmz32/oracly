/// About contact email — mailto with clipboard fallback.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/help/copy/help_copy.dart';
import '../../../features/help/services/support_mail_launcher.dart';
import '../../../features/help/services/support_report_payload.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../../shared/widgets/oracly_pressable.dart';

class AboutContactEmail extends StatelessWidget {
  const AboutContactEmail({super.key});

  Future<void> _open(BuildContext context) async {
    final result = await SupportMailLauncher.send(
      SupportReportPayload.generalContact(),
    );
    if (!context.mounted) return;
    OraclySnackBar.show(
      context,
      message: result == SupportMailResult.opened
          ? HelpCopy.mailOpened
          : HelpCopy.mailCopied,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: () => _open(context),
      child: Text(
        SupportReportPayload.supportEmail,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.gold,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.gold.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
