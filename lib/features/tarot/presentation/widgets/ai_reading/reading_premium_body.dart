/// OR-301+ — Premium sacred reading body with unique section cards.

library;



import 'dart:ui';



import 'package:flutter/material.dart';



import '../../../../../core/copy/reading_section_copy.dart';
import '../../../../../core/copy/session_ending_copy.dart';
import '../../../../../core/copy/transparency_copy.dart';

import '../../../../../core/theme/app_colors.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';

import '../../../../../core/widgets/transparency_footnote.dart';

import '../../../theme/tarot_tokens.dart';

import 'ai_reading_content.dart';

import 'reading_affirmation_card.dart';

import 'reading_cosmic_message.dart';
import 'reading_flow_connector.dart';
import 'reading_energy_meter.dart';

import 'reading_premium_header.dart';

import 'reading_premium_section_card.dart';

import 'reading_premium_utils.dart';

import 'reading_sacred_rhythm.dart';

import 'reading_section_theme.dart';

import 'reading_universal_frequency_card.dart';



class ReadingPremiumBody extends StatelessWidget {

  const ReadingPremiumBody({

    super.key,

    required this.content,

    required this.sectionMaster,

    required this.panelOpacity,

    required this.ambientPhase,

    this.exitProgress = 0,

    this.cardActive = true,

  });



  final AiReadingContent content;

  final double sectionMaster;

  final double panelOpacity;

  final double ambientPhase;

  final double exitProgress;

  final bool cardActive;



  bool _showHiddenMessage() {

    final tagline = content.tagline.trim();

    if (tagline.isEmpty) return false;

    if (tagline == content.cardName.trim()) return false;

    if (tagline == content.generalMeaning.trim()) return false;

    return true;

  }



  @override

  Widget build(BuildContext context) {

    final energy = ReadingPremiumUtils.energyValues(content);

    final affirmation = ReadingPremiumUtils.affirmationFrom(content);

    final frequency = ReadingPremiumUtils.universalFrequency(content);

    final showHidden = _showHiddenMessage();



    return ImageFiltered(

      imageFilter: ImageFilter.blur(

        sigmaX: exitProgress * 5,

        sigmaY: exitProgress * 5,

      ),

      child: Padding(

        padding: TarotTokens.screenPadding.copyWith(top: 0, bottom: 0),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            ReadingPremiumHeader(

              content: content,

              progress: sectionMaster,

              exitProgress: exitProgress,

              cardActive: cardActive,

            ),

            Opacity(

              opacity: panelOpacity * (1 - exitProgress * 0.35),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [

                  SizedBox(height: ReadingSacredRhythm.beforeInterpretation),

                  const ReadingFlowConnector(
                    label: ReadingSectionCopy.bridgeToMeaning,
                    compact: true,
                  ),

                  ReadingPremiumSectionCard(

                    kind: ReadingSectionKind.general,

                    title: ReadingSectionCopy.meaning,

                    body: content.generalMeaning,

                    index: 0,

                    master: sectionMaster,

                    ambientPhase: ambientPhase,

                    exitProgress: exitProgress,

                    emphasizeBody: true,

                    preserveFullText: true,

                  ),

                  ReadingPremiumSectionCard(

                    kind: ReadingSectionKind.love,

                    title: ReadingSectionCopy.love,

                    body: content.love,

                    index: 1,

                    master: sectionMaster,

                    ambientPhase: ambientPhase,

                    exitProgress: exitProgress,

                  ),

                  ReadingPremiumSectionCard(

                    kind: ReadingSectionKind.career,

                    title: ReadingSectionCopy.career,

                    body: content.career,

                    index: 2,

                    master: sectionMaster,

                    ambientPhase: ambientPhase,

                    exitProgress: exitProgress,

                  ),

                  ReadingPremiumSectionCard(

                    kind: ReadingSectionKind.money,

                    title: ReadingSectionCopy.money,

                    body: content.money,

                    index: 3,

                    master: sectionMaster,

                    ambientPhase: ambientPhase,

                    exitProgress: exitProgress,

                  ),

                  const ReadingFlowConnector(
                    label: ReadingSectionCopy.bridgeToReflection,
                  ),

                  ReadingPremiumSectionCard(

                    kind: ReadingSectionKind.spiritual,

                    title: ReadingSectionCopy.spiritual,

                    body: content.spiritualGuidance,

                    index: 4,

                    master: sectionMaster,

                    ambientPhase: ambientPhase,

                    exitProgress: exitProgress,

                    preserveFullText: true,

                  ),

                  if (showHidden)

                    ReadingPremiumSectionCard(

                      kind: ReadingSectionKind.hidden,

                      title: ReadingSectionCopy.hidden,

                      body: content.tagline,

                      index: 5,

                      master: sectionMaster,

                      ambientPhase: ambientPhase,

                      exitProgress: exitProgress,

                    ),

                  ReadingPremiumSectionCard(

                    kind: ReadingSectionKind.warning,

                    title: ReadingSectionCopy.suggestion,

                    body: content.dailyAdvice,

                    index: 6,

                    master: sectionMaster,

                    ambientPhase: ambientPhase,

                    exitProgress: exitProgress,

                    preserveFullText: true,

                  ),

                  ReadingPremiumSectionCard(

                    kind: ReadingSectionKind.lucky,

                    title: ReadingSectionCopy.lucky,

                    body: content.luckyEnergy,

                    index: 7,

                    master: sectionMaster,

                    ambientPhase: ambientPhase,

                    exitProgress: exitProgress,

                  ),

                  ReadingEnergyMeter(

                    love: energy.love,

                    career: energy.career,

                    spiritual: energy.spiritual,

                    index: 8,

                    master: sectionMaster,

                    exitProgress: exitProgress,

                  ),

                  ReadingUniversalFrequencyCard(

                    data: frequency,

                    index: 9,

                    master: sectionMaster,

                    exitProgress: exitProgress,

                  ),

                  const _ReflectionThreshold(),

                  ReadingAffirmationCard(

                    text: affirmation,

                    index: 10,

                    master: sectionMaster,

                    exitProgress: exitProgress,

                  ),

                  ReadingCosmicMessage(

                    message: SessionEndingCopy.lastingReflection(content),

                    index: 11,

                    master: sectionMaster,

                    exitProgress: exitProgress,

                  ),

                  const _ClosingBreath(),

                  const TransparencyFootnote(
                    text: TransparencyCopy.interpretationFootnote,
                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }

}



/// A whisper divider — connects sections without breaking calm.
class _ReflectionThreshold extends StatelessWidget {
  const _ReflectionThreshold();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: ReadingSacredRhythm.beforeReflection,
        bottom: AppSpacing.md,
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 52,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.transparent,
                    AppColors.gold.withValues(alpha: 0.22),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            ReadingSectionCopy.bridgeToClosing,
            textAlign: TextAlign.center,
            style: ReadingTypography.sectionLabel(
              fontSize: 10,
              color: AppColors.textHint.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}



/// Soft landing after the final reflection beat.

class _ClosingBreath extends StatelessWidget {

  const _ClosingBreath();



  @override

  Widget build(BuildContext context) {

    return SizedBox(height: ReadingSacredRhythm.afterReflection);

  }

}

