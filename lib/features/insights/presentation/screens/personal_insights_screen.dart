/// SPRINT-004 — Personal Insights letter experience.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/oracly_header_action.dart';
import '../../../../core/security/ai_error_sanitizer.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../core/widgets/transparency_footnote.dart';
import '../../../../features/home/widgets/home_cinematic_background.dart';
import '../../../../shared/ui/oracly_bottom_sheet.dart';
import '../../../../shared/ui/oracly_dialog.dart';
import '../../../../shared/ui/oracly_sheet_action.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/oracly_cinematic_loading.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../controllers/personal_insights_controller.dart';
import '../../copy/personal_insights_copy.dart';
import '../../providers/insights_providers.dart';
import '../widgets/insight_letter_card.dart';
import '../widgets/insights_empty_state.dart';

class PersonalInsightsScreen extends ConsumerStatefulWidget {
  const PersonalInsightsScreen({super.key});

  @override
  ConsumerState<PersonalInsightsScreen> createState() =>
      _PersonalInsightsScreenState();
}

class _PersonalInsightsScreenState extends ConsumerState<PersonalInsightsScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(personalInsightsControllerProvider);
    final state = controller.state;

    return OraclyScaffold(
      backgroundOverlay: const HomeCosmicBackground(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Align(
          child: OraclyHeaderAction(
            icon: AppIcons.back,
            label: OraclyL10n.t(L10nKeys.back),
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text(PersonalInsightsCopy.screenTitle),
        centerTitle: true,
        actions: [
          if (state.phase == PersonalInsightsPhase.ready)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OraclyHeaderAction(
                icon: Icons.more_vert_rounded,
                label: PersonalInsightsCopy.privacyTitle,
                onTap: () => _showActionsSheet(controller),
              ),
            ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: CraftsmanshipRhythm.appear,
        child: _body(state, controller),
      ),
    );
  }

  Widget _body(PersonalInsightsState state, PersonalInsightsController controller) {
    return switch (state.phase) {
      PersonalInsightsPhase.loading => const OraclyCinematicLoading(
          key: ValueKey('loading'),
          compact: true,
        ),
      PersonalInsightsPhase.empty => const InsightsEmptyState(
          key: ValueKey('empty'),
        ),
      PersonalInsightsPhase.error => Center(
          key: const ValueKey('error'),
          child: Padding(
            padding: AppSpacing.screen,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AiErrorSanitizer.guard(
                    state.error,
                    fallback: ResilienceCopy.genericLoadFailed,
                  ),
                  textAlign: TextAlign.center,
                  style: ReadingTypography.body(),
                ),
                SizedBox(height: AppSpacing.lg),
                OraclyGoldButton(
                  label: OraclyL10n.t('insights.retry'),
                  onPressed: controller.load,
                ),
              ],
            ),
          ),
        ),
      PersonalInsightsPhase.ready => _letterContent(state, controller),
    };
  }

  Widget _letterContent(
    PersonalInsightsState state,
    PersonalInsightsController controller,
  ) {
    final summary = state.summary!;
    final insights = summary.insights;

    return ListView(
      key: const ValueKey('ready'),
      padding: AppSpacing.screen,
      children: [
        Text(
          summary.salutation,
          style: ReadingTypography.opening(),
        ),
        if (summary.growthSnapshot != null) ...[
          SizedBox(height: AppSpacing.xl),
          Text(
            summary.growthSnapshot!.narrative,
            style: ReadingTypography.bodyCore(),
          ),
        ],
        if (insights.isNotEmpty) ...[
          SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < insights.length; i++)
            InsightLetterCard(
              insight: insights[i],
              entrance: 1,
              onMore: () => _showInsightActions(controller, insights[i].id),
            ),
        ],
        if (summary.patterns.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          Text(
            OraclyL10n.t('insights.patterns'),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          for (final pattern in summary.patterns)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                '• ${pattern.observation}',
                style: ReadingTypography.body(),
              ),
            ),
        ],
        if (summary.closingNote != null) ...[
          SizedBox(height: AppSpacing.xl),
          Text(
            summary.closingNote!,
            style: ReadingTypography.reflection(
              color: AppColors.textMuted,
            ),
          ),
        ],
        SizedBox(height: AppSpacing.lg),
        TransparencyFootnote(text: PersonalInsightsCopy.footnote),
        SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  void _showActionsSheet(PersonalInsightsController controller) {
    OraclyBottomSheet.show<void>(
      context,
      title: PersonalInsightsCopy.privacyTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OraclySheetAction(
            icon: Icons.refresh_rounded,
            label: PersonalInsightsCopy.regenerateAction,
            onTap: () async {
              Navigator.pop(context);
              await controller.regenerate();
              if (!context.mounted) return;
              OraclySnackBar.show(
                context,
                message: PersonalInsightsCopy.regeneratedConfirmation,
              );
            },
          ),
          OraclySheetAction(
            icon: Icons.upload_outlined,
            label: PersonalInsightsCopy.exportAction,
            onTap: () async {
              Navigator.pop(context);
              final text = controller.exportText();
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              OraclySnackBar.show(
                context,
                message: PersonalInsightsCopy.exportedConfirmation,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showInsightActions(PersonalInsightsController controller, String id) {
    OraclyBottomSheet.show<void>(
      context,
      title: PersonalInsightsCopy.privacyTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OraclySheetAction(
            icon: Icons.visibility_off_outlined,
            label: PersonalInsightsCopy.hideAction,
            onTap: () async {
              Navigator.pop(context);
              await controller.hideInsight(id);
              if (!context.mounted) return;
              OraclySnackBar.show(
                context,
                message: PersonalInsightsCopy.hiddenConfirmation,
              );
            },
          ),
          OraclySheetAction(
            icon: Icons.delete_outline,
            label: PersonalInsightsCopy.deleteAction,
            destructive: true,
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await OraclyDialog.confirm(
                context,
                title: PersonalInsightsCopy.deleteAction,
                message: PersonalInsightsCopy.deletePrompt,
                confirmLabel: PersonalInsightsCopy.deleteAction,
                cancelLabel: OraclyL10n.t('trust.delete_cancel'),
                destructive: true,
              );
              if (confirmed == true) {
                await controller.deleteInsight(id);
                if (!context.mounted) return;
                OraclySnackBar.show(
                  context,
                  message: PersonalInsightsCopy.deletedConfirmation,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
