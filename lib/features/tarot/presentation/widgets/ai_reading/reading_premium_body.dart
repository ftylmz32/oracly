/// Premium reading body: question → cards → story stack (actions follow).
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/insight_copy/widgets/insight_copy_link.dart';
import '../../../../../core/theme/oracly_quiet_motion.dart';
import '../../../theme/tarot_tokens.dart';
import '../tarot_flow_progress.dart';
import 'ai_reading_content.dart';
import 'tarot_insight_copy.dart';
import 'reading_premium_header.dart';
import 'reading_premium_sections.dart';
import 'reading_story_strip.dart';

class ReadingPremiumBody extends StatelessWidget {
  const ReadingPremiumBody({
    super.key,
    required this.content,
    required this.sectionMaster,
    required this.panelOpacity,
    required this.ambientPhase,
    this.exitProgress = 0,
  });

  final AiReadingContent content;
  final double sectionMaster;
  final double panelOpacity;
  final double ambientPhase;
  final double exitProgress;

  @override
  Widget build(BuildContext context) {
    Widget body = Padding(
      padding: TarotTokens.screenPadding.copyWith(top: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TarotFlowProgress(step: TarotRitualStep.reading),
          ReadingPremiumHeader(
            content: content,
            progress: sectionMaster,
            exitProgress: exitProgress,
          ),
          ReadingStoryStrip(
            content: content,
            progress: sectionMaster,
            exitProgress: exitProgress,
          ),
          Opacity(
            opacity: panelOpacity * (1 - exitProgress * 0.35),
            child: ReadingPremiumSections(
              content: content,
              sectionMaster: sectionMaster,
              ambientPhase: ambientPhase,
              exitProgress: exitProgress,
            ),
          ),
          SizedBox(height: TarotTokens.screenPadding.top),
          InsightCopyLink(text: TarotInsightCopy.fromContent(content)),
        ],
      ),
    );
    if (exitProgress <= 0.01) return body;
    // Soft exit — skip ImageFilter on HD+ (opacity already fades content).
    if (OraclyQuietMotion.constrained(context)) {
      return Opacity(opacity: 1 - exitProgress * 0.45, child: body);
    }
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: exitProgress * 5,
        sigmaY: exitProgress * 5,
      ),
      child: body,
    );
  }
}
