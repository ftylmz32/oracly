/// Yardım — report a problem or contact support. Metadata only.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/oracly_header_action.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/premium/presentation/widgets/premium_background.dart';
import '../../../screens/settings/reference/settings_reference_group.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../../shared/widgets/oracly_entrance.dart';
import '../copy/help_copy.dart';
import '../services/support_mail_launcher.dart';
import '../services/support_report_payload.dart';
import 'widgets/help_diagnostics_section.dart';
import 'widgets/help_report_sheet.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _send(
    BuildContext context,
    SupportReportPayload payload,
  ) async {
    final result = await SupportMailLauncher.send(payload);
    if (!context.mounted) return;
    OraclySnackBar.show(
      context,
      message: result == SupportMailResult.opened
          ? HelpCopy.mailOpened
          : HelpCopy.mailCopied,
    );
  }

  Future<void> _report(BuildContext context) async {
    final category = await showHelpReportSheet(context);
    if (category == null || !context.mounted) return;
    await _send(context, SupportReportPayload.fromCategory(category));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PremiumBackground(),
          CustomScrollView(
            physics: CraftsmanshipRhythm.scrollPhysics,
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.black.withValues(alpha: 0.45),
                leading: Align(
                  child: OraclyHeaderAction(
                    icon: AppIcons.back,
                    label: OraclyL10n.t(L10nKeys.back),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                title: Text(HelpCopy.title),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OraclyEntrance(
                        child: Text(
                          HelpCopy.subtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      OraclyEntrance.staggered(
                        index: 1,
                        child: SettingsReferenceGroup(
                          title: HelpCopy.title,
                          rows: [
                            SettingsReferenceRow(
                              icon: Icons.flag_outlined,
                              title: HelpCopy.report,
                              subtitle: HelpCopy.reportSubtitle,
                              showChevron: true,
                              onTap: () => _report(context),
                            ),
                            SettingsReferenceRow(
                              icon: Icons.mail_outline_rounded,
                              title: HelpCopy.contact,
                              subtitle: HelpCopy.contactSubtitle,
                              showChevron: true,
                              onTap: () => _send(
                                context,
                                SupportReportPayload.generalContact(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      OraclyEntrance.staggered(
                        index: 2,
                        child: const HelpDiagnosticsSection(),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      OraclyEntrance.staggered(
                        index: 3,
                        child: Text(
                          HelpCopy.privacyNote,
                          textAlign: TextAlign.center,
                          style: ReadingTypography.footnote(),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
