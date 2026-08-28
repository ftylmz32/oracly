/// Hierarchy: theme → story → relations → cards → details → direction.
library;

import 'package:flutter/material.dart';

import '../../../../../core/reading_ux/reading_expand_section.dart';
import '../../../../../core/widgets/transparency_footnote.dart';
import '../../../copy/tarot_polish_copy.dart';
import 'ai_reading_content.dart';
import 'reading_detail_layers.dart';
import 'reading_premium_animations.dart';
import 'reading_premium_cards_block.dart';
import 'reading_premium_section_card.dart';
import 'reading_premium_threshold.dart';
import 'reading_result_separator.dart';
import 'reading_sacred_rhythm.dart';
import 'reading_section_theme.dart';
import 'reading_story_relations.dart';
import 'reading_theme_band.dart';

class ReadingPremiumSections extends StatelessWidget {
  const ReadingPremiumSections({
    super.key,
    required this.content,
    required this.sectionMaster,
    required this.ambientPhase,
    required this.exitProgress,
  });

  final AiReadingContent content;
  final double sectionMaster;
  final double ambientPhase;
  final double exitProgress;

  @override
  Widget build(BuildContext context) {
    final narrative = content.luckyEnergy.trim().isNotEmpty
        ? content.luckyEnergy
        : content.generalMeaning;
    final direction = content.closingMessage.trim().isNotEmpty
        ? content.closingMessage
        : content.dailyAdvice;
    final relations = ReadingStoryRelations.of(content);
    final dim = 1 - readingPremiumGuidanceDim(sectionMaster);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ReadingSacredRhythm.interpretationMaxWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: ReadingSacredRhythm.beforeInterpretation),
            Opacity(
              opacity: dim,
              child: ReadingThemeBand(content: content),
            ),
            Opacity(
              opacity: dim,
              child: ReadingExpandSection(
                title: TarotPolishCopy.storyTitle,
                body: narrative,
                hero: true,
              ),
            ),
            if (relations.isNotEmpty) ...[
              const ReadingResultActGap(),
              Opacity(
                opacity: dim,
                child: ReadingExpandSection(
                  title: TarotPolishCopy.relationsTitle,
                  body: relations,
                ),
              ),
            ],
            const ReadingResultSeparator(),
            Opacity(
              opacity: dim,
              child: ReadingPremiumCardsBlock(
                content: content,
                sectionMaster: sectionMaster,
              ),
            ),
            const ReadingResultActGap(),
            Opacity(
              opacity: dim,
              child: ReadingDetailLayers(content: content),
            ),
            const ReadingPremiumThreshold(),
            if (direction.trim().isNotEmpty)
              ReadingPremiumSectionCard(
                kind: ReadingSectionKind.spiritual,
                title: TarotPolishCopy.directionTitle,
                body: direction,
                index: 20,
                master: sectionMaster,
                ambientPhase: ambientPhase,
                exitProgress: exitProgress,
                emphasizeBody: true,
                preserveFullText: true,
              ),
            const ReadingPremiumClosingBreath(),
            TransparencyFootnote(
              text: TarotPolishCopy.readingFootnote(
                fromAi: content.isAiInterpretation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
