/// Premium celestial report spine - theme, message, attention, next step.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_narrative_block.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/astrology_presentation_copy.dart';
import '../../models/astrology_daily_reading.dart';
import 'astrology_reading_presentation.dart';
import 'astrology_result_beat.dart';

class AstrologyResultReport extends StatelessWidget {
  const AstrologyResultReport({
    super.key,
    required this.reading,
    this.themeLabels = const <String>[],
  });

  final AstrologyDailyReading reading;
  final List<String> themeLabels;

  @override
  Widget build(BuildContext context) {
    final theme = AstrologyReadingPresentation.mainTheme(reading, themeLabels);
    final message = reading.overall.trim();
    final attention = AstrologyReadingPresentation.attentionPoint(reading);
    final next = AstrologyReadingPresentation.nextAction(reading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (theme.isNotEmpty)
          AstrologyResultBeat(
            label: AstrologyPresentationCopy.reportTheme,
            kind: AstrologyResultBeatKind.theme,
            index: 0,
            child: AstrologyResultThemeLine(text: theme),
          ),
        if (message.isNotEmpty)
          AstrologyResultBeat(
            label: AstrologyPresentationCopy.reportMessage,
            kind: AstrologyResultBeatKind.message,
            index: 1,
            child: ChamberNarrativeBlock(hero: true, body: message),
          ),
        if (attention.isNotEmpty)
          AstrologyResultBeat(
            label: AstrologyPresentationCopy.reportAttention,
            kind: AstrologyResultBeatKind.attention,
            index: 2,
            child: Text(
              attention,
              style: ReadingTypography.body(
                color: OraclyChrome.cream.withValues(
                  alpha: CraftsmanshipRhythm.bodyInk,
                ),
              ),
            ),
          ),
        if (next.isNotEmpty)
          AstrologyResultBeat(
            label: AstrologyPresentationCopy.reportNext,
            kind: AstrologyResultBeatKind.action,
            index: 3,
            child: Text(
              next,
              style: ReadingTypography.bodyCore(
                color: OraclyChrome.cream.withValues(
                  alpha: CraftsmanshipRhythm.titleInk,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
