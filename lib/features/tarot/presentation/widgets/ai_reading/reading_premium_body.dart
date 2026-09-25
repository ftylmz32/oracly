/// Premium reading body: question → spread → narrative stack (Phase 7E).
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/insight_copy/widgets/insight_copy_link.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/oracly_quiet_motion.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../domain/models/tarot_spread.dart';
import '../../../theme/tarot_tokens.dart';
import '../tarot_flow_progress.dart';
import 'ai_reading_content.dart';
import 'tarot_insight_copy.dart';
import 'reading_premium_header.dart';
import 'reading_premium_sections.dart';
import 'reading_result_spread.dart';

class ReadingPremiumBody extends StatelessWidget {
  const ReadingPremiumBody({
    super.key,
    required this.content,
    required this.sectionMaster,
    required this.panelOpacity,
    required this.ambientPhase,
    this.spread,
    this.exitProgress = 0,
  });

  final AiReadingContent content;
  final TarotSpreadType? spread;
  final double sectionMaster;
  final double panelOpacity;
  final double ambientPhase;
  final double exitProgress;

  @override
  Widget build(BuildContext context) {
    if (content.isSafetyResponse) {
      return _SafetyReadingBody(
        reason: content.generalMeaning,
        exitProgress: exitProgress,
      );
    }

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
          ReadingResultSpread(
            content: content,
            spread: spread,
            progress: sectionMaster,
            exitProgress: exitProgress,
            showSpreadLabel: false,
          ),
          Opacity(
            opacity: panelOpacity * (1 - exitProgress * 0.35),
            child: ReadingPremiumSections(
              content: content,
              spread: spread,
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

/// Localized safety reason only — no Tarot story / cards / insight copy.
class _SafetyReadingBody extends StatelessWidget {
  const _SafetyReadingBody({
    required this.reason,
    required this.exitProgress,
  });

  final String reason;
  final double exitProgress;

  @override
  Widget build(BuildContext context) {
    final panel = Padding(
      padding: TarotTokens.screenPadding.copyWith(top: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TarotFlowProgress(step: TarotRitualStep.reading),
          Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.xl,
            ),
            child: Text(
              reason,
              style: ReadingTypography.body(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
    if (exitProgress <= 0.01) return panel;
    return Opacity(opacity: 1 - exitProgress * 0.45, child: panel);
  }
}
