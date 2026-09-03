/// My Data / Privacy Control Center — show stored data, real controls only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/transparency_copy.dart';
import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/oracly_header_action.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../features/premium/presentation/widgets/premium_background.dart';
import '../../../../features/premium/presentation/widgets/settings_tiles.dart';
import '../../../../shared/widgets/oracly_cinematic_loading.dart';
import '../../../../shared/widgets/oracly_entrance.dart';
import '../../copy/privacy_control_copy.dart';
import '../../providers/privacy_control_providers.dart';
import '../../../quality_loop/widgets/quality_loop_report_section.dart';
import '../widgets/privacy_control_actions_section.dart';
import '../widgets/privacy_control_summary_section.dart';

class PrivacyControlCenterScreen extends ConsumerWidget {
  const PrivacyControlCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(privacyControlSnapshotProvider);

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
                title: Text(
                  PrivacyControlCopy.title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OraclyEntrance(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: Text(
                          PrivacyControlCopy.subtitle,
                          style: ReadingTypography.opening(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    OraclyEntrance(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          TransparencyCopy.privacyIntro,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                            height: CraftsmanshipRhythm.bodyLineHeight,
                          ),
                        ),
                      ),
                    ),
                    SettingsSectionHeader(title: PrivacyControlCopy.sectionData),
                    snapshot.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: OraclyCinematicLoading(compact: true),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (data) => OraclyEntrance.staggered(
                        index: 0,
                        child: PrivacyControlSummarySection(snapshot: data),
                      ),
                    ),
                    const QualityLoopReportSection(),
                    SettingsSectionHeader(
                      title: PrivacyControlCopy.sectionActions,
                    ),
                    const PrivacyControlActionsSection(),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
