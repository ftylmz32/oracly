/// Hierarchy: narrative hero → cards → life areas → direction (Phase 7E).
library;

import 'package:flutter/material.dart';

import '../../../../../core/design_system/oracly_chrome.dart';
import '../../../../../core/reading_ux/reading_expand_section.dart';
import '../../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../core/widgets/transparency_footnote.dart';
import '../../../copy/tarot_polish_copy.dart';
import '../../../domain/models/tarot_spread.dart';
import 'ai_reading_content.dart';
import 'reading_detail_layers.dart';
import 'reading_narrative_hero.dart';
import 'reading_narrative_selector.dart';
import 'reading_premium_animations.dart';
import 'reading_premium_cards_block.dart';
import 'reading_premium_section_card.dart';
import 'reading_premium_threshold.dart';
import 'reading_result_mode.dart';
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
    this.spread,
  });

  final AiReadingContent content;
  final TarotSpreadType? spread;
  final double sectionMaster;
  final double ambientPhase;
  final double exitProgress;

  @override
  Widget build(BuildContext context) {
    final narrative = ReadingNarrativeSelector.select(content);
    final v2 = ReadingResultModeResolver.isNarrativeV2(spread);
    // Local adjacent prose is NOT verified Narrative Evidence — V2 omits it.
    final relations = v2 ? '' : ReadingStoryRelations.of(content);
    final dim = 1 - readingPremiumGuidanceDim(sectionMaster);
    final hasCards = content.drawnCards.isNotEmpty ||
        content.cardReadings.trim().isNotEmpty;

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
            Opacity(opacity: dim, child: ReadingThemeBand(content: content)),
            Opacity(
              opacity: dim,
              child: ReadingNarrativeHero(
                opening: narrative.openingSummary,
                body: narrative.primaryNarrative,
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
            if (hasCards) ...[
              const ReadingResultSeparator(),
              Opacity(
                opacity: dim,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: CraftsmanshipRhythm.afterTitle,
                  ),
                  child: Text(
                    TarotPolishCopy.cardsTitle,
                    style: ReadingTypography.sectionLabel(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: dim,
                child: ReadingPremiumCardsBlock(
                  content: content,
                  sectionMaster: sectionMaster,
                ),
              ),
            ],
            const ReadingResultActGap(),
            Opacity(
              opacity: dim,
              child: ReadingDetailLayers(content: content),
            ),
            const ReadingPremiumThreshold(),
            if (narrative.direction.isNotEmpty)
              ReadingPremiumSectionCard(
                kind: ReadingSectionKind.spiritual,
                title: TarotPolishCopy.directionTitle,
                body: narrative.direction,
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
