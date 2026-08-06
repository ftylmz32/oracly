/// SPRINT-004 — Personal Insights letter experience.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../core/widgets/transparency_footnote.dart';
import '../../../../features/home/widgets/home_cinematic_background.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
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
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(PersonalInsightsCopy.screenTitle),
        centerTitle: true,
        actions: [
          if (state.phase == PersonalInsightsPhase.ready)
            IconButton(
              onPressed: () => _showActionsSheet(controller),
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: PersonalInsightsCopy.privacyTitle,
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
      PersonalInsightsPhase.loading => const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(color: AppColors.gold),
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
                  ResilienceCopy.genericLoadFailed,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.body(),
                ),
                SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: controller.load,
                  child: const Text('Tekrar dene'),
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
            'Tekrar eden desenler',
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
        const TransparencyFootnote(text: PersonalInsightsCopy.footnote),
        SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  void _showActionsSheet(PersonalInsightsController controller) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: Text(PersonalInsightsCopy.regenerateAction),
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
            ListTile(
              leading: const Icon(Icons.upload_outlined),
              title: Text(PersonalInsightsCopy.exportAction),
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
      ),
    );
  }

  void _showInsightActions(PersonalInsightsController controller, String id) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: Text(PersonalInsightsCopy.hideAction),
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
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                PersonalInsightsCopy.deleteAction,
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(PersonalInsightsCopy.deleteAction),
                    content: Text(PersonalInsightsCopy.deletePrompt),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Vazgeç'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          PersonalInsightsCopy.deleteAction,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
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
      ),
    );
  }
}
