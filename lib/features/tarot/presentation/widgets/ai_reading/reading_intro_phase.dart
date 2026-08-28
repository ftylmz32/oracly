/// OR-301+ / OR-434 / EPIC-002 — Reading intro — breath between reveal and interpretation.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../../core/copy/first_session_copy.dart';
import '../../../../../core/copy/reading_flow_copy.dart';
import '../../../../../core/first_session/first_session_scope.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../theme/tarot_emotional_rhythm.dart';
import 'ai_reading_content.dart';

class ReadingIntroPhase extends StatelessWidget {
  const ReadingIntroPhase({
    super.key,
    required this.content,
    required this.progress,
    required this.cardLift,
  });

  final AiReadingContent content;
  final double progress;
  final double cardLift;

  @override
  Widget build(BuildContext context) {
    final opacity = progress.clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          SizedBox(height: AppSpacing.xxl + AppSpacing.xl + cardLift),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              ReadingFlowCopy.introBreath,
              textAlign: TextAlign.center,
              style: ReadingTypography.sectionLabel(
                fontSize: 14,
                color: AppColors.goldLight.withValues(alpha: 0.78),
              ).copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg - AppSpacing.xs),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl + AppSpacing.sm),
            child: Text(
              FirstSessionCopy.introPreparingFor(
                isFirstSession: FirstSessionScope.of(context),
              ),
              textAlign: TextAlign.center,
              style: ReadingTypography.opening(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Intro progress — breath, pause, then yield to the reading.
abstract final class ReadingIntroTimeline {
  ReadingIntroTimeline._();

  static const Duration duration = Duration(milliseconds: 1000);

  static double fogFill(double t) {
    final base = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
    final calm = TarotEmotionalRhythm.calmDampen(
      TarotEmotionalRhythm.peakPulse(t, centre: 0.48, width: 0.22),
    );
    return base * calm;
  }

  static double introOpacity(double t) {
    final p = t.clamp(0.0, 1.0);
    if (p < 0.12) {
      return Curves.easeOut.transform((p / 0.12).clamp(0.0, 1.0));
    }
    if (p > 0.78) {
      return Curves.easeIn.transform(((1 - p) / 0.22).clamp(0.0, 1.0));
    }
    return 1;
  }

  static double cardLift(double t) {
    final p = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    return -lerpDouble(0, 8, p)!;
  }
}
