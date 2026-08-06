/// SPRINT-001 — Complete Dream Analysis journey.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../features/home/widgets/home_cinematic_background.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/chamber_waiting_orb.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../controllers/dream_analysis_controller.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream_emotion.dart';
import '../../providers/dream_providers.dart';
import '../widgets/dream_emotion_picker.dart';
import '../widgets/dream_insights_panel.dart';
import '../widgets/dream_tag_input.dart';
import '../widgets/dream_understanding_panel.dart';
import '../widgets/dream_voice_slot.dart';

class DreamScreen extends ConsumerStatefulWidget {
  const DreamScreen({super.key});

  @override
  ConsumerState<DreamScreen> createState() => _DreamScreenState();
}

class _DreamScreenState extends ConsumerState<DreamScreen> {
  final _narrativeController = TextEditingController();
  final _selectedEmotions = <DreamEmotionId>{};
  var _tags = <String>[];

  @override
  void dispose() {
    _narrativeController.dispose();
    super.dispose();
  }

  Future<void> _submit(DreamAnalysisController controller) async {
    final text = _narrativeController.text.trim();
    if (text.length < 12) {
      OraclySnackBar.show(context, message: DreamCopy.narrativeTooShort);
      return;
    }

    final emotions = _selectedEmotions
        .map((id) => DreamEmotion(id: id))
        .toList();

    await controller.submit(
      narrative: text,
      emotions: emotions,
      tags: _tags,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(dreamAnalysisControllerProvider);

    return OraclyScaffold(
      backgroundOverlay: const HomeCosmicBackground(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(DreamCopy.screenTitle),
        centerTitle: true,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        child: switch (controller.phase) {
          DreamJourneyPhase.entry => _EntryView(
              key: const ValueKey('entry'),
              controller: _narrativeController,
              selectedEmotions: _selectedEmotions,
              tags: _tags,
              onEmotionToggle: (id) {
                setState(() {
                  if (_selectedEmotions.contains(id)) {
                    _selectedEmotions.remove(id);
                  } else {
                    _selectedEmotions.add(id);
                  }
                });
              },
              onTagsChanged: (tags) => setState(() => _tags = tags),
              onSubmit: () => _submit(controller),
            ),
          DreamJourneyPhase.organizing ||
          DreamJourneyPhase.reflecting =>
            _LoadingView(
              key: ValueKey(controller.phase.name),
              message: controller.phase == DreamJourneyPhase.organizing
                  ? DreamCopy.organizing
                  : DreamCopy.reflecting,
            ),
          DreamJourneyPhase.complete => _ResultView(
              key: const ValueKey('complete'),
              controller: controller,
              onNewDream: () {
                controller.reset();
                _narrativeController.clear();
                setState(() {
                  _selectedEmotions.clear();
                  _tags = [];
                });
              },
            ),
          DreamJourneyPhase.error => _ErrorView(
              key: const ValueKey('error'),
              message: controller.errorMessage ?? DreamCopy.narrativeTooShort,
              onRetry: () => _submit(controller),
              onBack: controller.reset,
            ),
        },
      ),
    );
  }
}

class _EntryView extends StatelessWidget {
  const _EntryView({
    super.key,
    required this.controller,
    required this.selectedEmotions,
    required this.tags,
    required this.onEmotionToggle,
    required this.onTagsChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final Set<DreamEmotionId> selectedEmotions;
  final List<String> tags;
  final ValueChanged<DreamEmotionId> onEmotionToggle;
  final ValueChanged<List<String>> onTagsChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.screenHorizontal.copyWith(
        top: AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(DreamCopy.entryHeadline, style: ReadingTypography.cardTitle()),
          SizedBox(height: AppSpacing.sm),
          Text(DreamCopy.entryDescription, style: ReadingTypography.opening()),
          SizedBox(height: AppSpacing.lg),
          TextField(
            controller: controller,
            maxLines: 7,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: DreamCopy.narrativeHint,
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface.withValues(alpha: 0.65),
              border: OutlineInputBorder(
                borderRadius: AppRadius.md,
                borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.22)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.md,
                borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.22)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.md,
                borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.55)),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          const DreamVoiceSlot(),
          SizedBox(height: AppSpacing.lg),
          DreamEmotionPicker(
            selected: selectedEmotions,
            onToggle: onEmotionToggle,
          ),
          SizedBox(height: AppSpacing.lg),
          DreamTagInput(tags: tags, onChanged: onTagsChanged),
          SizedBox(height: AppSpacing.xl),
          OraclyButton(
            text: DreamCopy.beginAnalysis,
            isExpanded: true,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenHorizontal,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ChamberWaitingOrb(),
            SizedBox(height: AppSpacing.lg),
            Text(message, style: ReadingTypography.bodyCore()),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    super.key,
    required this.controller,
    required this.onNewDream,
  });

  final DreamAnalysisController controller;
  final VoidCallback onNewDream;

  @override
  Widget build(BuildContext context) {
    final dream = controller.dream;
    if (dream?.understanding == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.screenHorizontal.copyWith(
        top: AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DreamUnderstandingPanel(understanding: dream!.understanding!),
          SizedBox(height: AppSpacing.xl),
          DreamInsightsPanel(insights: dream.insights),
          SizedBox(height: AppSpacing.xl),
          OraclyButton(
            text: DreamCopy.saveAndClose,
            isExpanded: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(height: AppSpacing.sm),
          OraclyButton(
            text: 'Yeni rüya',
            type: OraclyButtonType.ghost,
            isExpanded: true,
            onPressed: onNewDream,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenHorizontal,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, style: ReadingTypography.bodyCore()),
            SizedBox(height: AppSpacing.lg),
            OraclyButton(text: 'Tekrar dene', onPressed: onRetry),
            SizedBox(height: AppSpacing.sm),
            OraclyButton(
              text: 'Geri',
              type: OraclyButtonType.ghost,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}
