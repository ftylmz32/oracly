/// Scrollable tarot entry body — deck, question, spreads.
library;

import 'package:flutter/material.dart';

import '../../../../../core/design_system/app_layout.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../copy/tarot_polish_copy.dart';
import '../../../domain/models/tarot_spread.dart';
import '../../../motion/tarot_entry_reveal.dart';
import '../../epic031/tarot_epic031_cost_hint.dart';
import '../../epic031/tarot_epic031_history.dart';
import '../../epic031/tarot_epic031_primary_button.dart';
import '../../epic031/tarot_epic031_title_block.dart';
import '../../destem/destem_entry_link.dart';
import '../intention_selection/intention_question_field.dart';
import 'tarot_entry_hero.dart';
import 'tarot_entry_spreads.dart';

class TarotEntryBody extends StatelessWidget {
  const TarotEntryBody({
    super.key,
    required this.heroHeight,
    required this.question,
    required this.spread,
    required this.onSpreadSelected,
    required this.onStart,
    required this.onHistory,
    this.onDestem,
    this.showCost = false,
    this.cost,
    this.starting = false,
    this.questionFocusNode,
  });

  final double heroHeight;
  final TextEditingController question;
  final FocusNode? questionFocusNode;
  final TarotSpreadType spread;
  final ValueChanged<TarotSpreadType> onSpreadSelected;
  final VoidCallback onStart;
  final VoidCallback onHistory;
  final VoidCallback? onDestem;
  final bool showCost;
  final int? cost;
  final bool starting;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: CraftsmanshipRhythm.scrollPhysics,
      padding: EdgeInsets.only(
        bottom: AppLayout.scrollBottomInset(context),
      ),
      child: TarotEntryReveal(
        title: const TarotEpic031TitleBlock(),
        hero: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: TarotEntryHero(height: heroHeight),
        ),
        rest: _EntryRest(
          question: question,
          questionFocusNode: questionFocusNode,
          spread: spread,
          onSpreadSelected: onSpreadSelected,
          onStart: onStart,
          onHistory: onHistory,
          onDestem: onDestem,
          showCost: showCost,
          cost: cost,
          starting: starting,
        ),
      ),
    );
  }
}

class _EntryRest extends StatelessWidget {
  const _EntryRest({
    required this.question,
    this.questionFocusNode,
    required this.spread,
    required this.onSpreadSelected,
    required this.onStart,
    required this.onHistory,
    this.onDestem,
    required this.showCost,
    required this.cost,
    required this.starting,
  });

  final TextEditingController question;
  final FocusNode? questionFocusNode;
  final TarotSpreadType spread;
  final ValueChanged<TarotSpreadType> onSpreadSelected;
  final VoidCallback onStart;
  final VoidCallback onHistory;
  final VoidCallback? onDestem;
  final bool showCost;
  final int? cost;
  final bool starting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.md),
        IntentionQuestionField(
          controller: question,
          focusNode: questionFocusNode,
          placeholder: TarotPolishCopy.entryQuestionHint,
          examples: TarotPolishCopy.entryQuestionExamples,
          onChanged: (_) {},
          onExampleTap: (example) {
            question.text = example;
            question.selection = TextSelection.collapsed(
              offset: example.length,
            );
          },
        ),
        SizedBox(height: AppSpacing.md),
        TarotEntrySpreads(selected: spread, onSelected: onSpreadSelected),
        if (showCost && cost != null) TarotEpic031CostHint(cost: cost!),
        SizedBox(height: AppSpacing.md),
        TarotEpic031PrimaryButton(
          label: TarotPolishCopy.startSpreadCta,
          onPressed: starting ? null : onStart,
        ),
        SizedBox(height: AppSpacing.sm),
        TarotEpic031History(onViewAll: onHistory, onEntryTap: onHistory),
        if (onDestem != null) ...[
          SizedBox(height: AppSpacing.s4),
          DestemEntryLink(onTap: onDestem!),
        ],
      ],
    );
  }
}
