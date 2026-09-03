/// Approved reference dream entry — hero, input, chips, guided prompts.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream_entry_context.dart';
import 'dream_entry_context_chips.dart';
import 'dream_entry_guided_questions.dart';
import 'dream_entry_input_card.dart';
import 'dream_reference_app_bar.dart';
import 'dream_reference_entry_hero.dart';
import 'dream_reference_tokens.dart';

class DreamReferenceEntryView extends StatelessWidget {
  const DreamReferenceEntryView({
    super.key,
    required this.controller,
    required this.selectedChips,
    required this.guidedAnswers,
    required this.onChipToggle,
    required this.onGuidedChanged,
    required this.onVoiceTap,
    required this.onSubmit,
    this.voiceEnabled = true,
  });

  final TextEditingController controller;
  final Set<DreamEntryChipId> selectedChips;
  final Map<DreamGuidedQuestionId, String> guidedAnswers;
  final ValueChanged<DreamEntryChipId> onChipToggle;
  final void Function(DreamGuidedQuestionId id, String value) onGuidedChanged;
  final VoidCallback onVoiceTap;
  final VoidCallback onSubmit;
  final bool voiceEnabled;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        DreamReferenceTokens.screenHorizontal,
        DreamReferenceTokens.screenTop,
        DreamReferenceTokens.screenHorizontal,
        DreamReferenceTokens.entryScrollBottomInset(context),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DreamReferenceAppBar(),
              SizedBox(height: AppSpacing.sm),
              const DreamReferenceEntryHero(),
              SizedBox(height: AppSpacing.lg),
              DreamEntryInputCard(
                controller: controller,
                onVoiceTap: onVoiceTap,
                voiceEnabled: voiceEnabled,
              ),
              SizedBox(height: AppSpacing.md),
              DreamEntryContextChips(
                selected: selectedChips,
                onToggle: onChipToggle,
              ),
              SizedBox(height: AppSpacing.lg),
              DreamEntryGuidedQuestions(
                answers: guidedAnswers,
                onChanged: onGuidedChanged,
              ),
              SizedBox(height: AppSpacing.lg),
              OraclyGoldButton(
                label: DreamCopy.submitCta,
                expanded: true,
                onPressed: onSubmit,
              ),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}