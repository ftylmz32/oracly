/// Help diagnostics panel — version/build visible; OS only on explicit copy.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../screens/settings/reference/settings_reference_group.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../copy/help_copy.dart';
import '../../services/support_diagnostics.dart';

class HelpDiagnosticsSection extends StatelessWidget {
  const HelpDiagnosticsSection({super.key});

  Future<void> _copy(BuildContext context) async {
    final text = SupportDiagnostics.shareText();
    assert(SupportDiagnostics.looksSafe(text));
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    OraclySnackBar.show(context, message: HelpCopy.diagnosticsCopied);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsReferenceGroup(
          title: HelpCopy.diagnosticsTitle,
          rows: [
            SettingsReferenceRow(
              icon: Icons.info_outline_rounded,
              title: HelpCopy.diagnosticsVersion,
              subtitle: SupportDiagnostics.appVersion,
            ),
            SettingsReferenceRow(
              icon: Icons.tag_rounded,
              title: HelpCopy.diagnosticsBuild,
              subtitle: SupportDiagnostics.build,
            ),
            SettingsReferenceRow(
              icon: Icons.copy_all_outlined,
              title: HelpCopy.diagnosticsCopy,
              subtitle: HelpCopy.diagnosticsCopyHint,
              showChevron: true,
              onTap: () => _copy(context),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          HelpCopy.diagnosticsPrivacy,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote().copyWith(
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
