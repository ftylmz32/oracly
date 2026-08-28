/// Supporting insights on the main Astrology hub (one story, no dashboard tiles).
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../models/astrology_daily_reading.dart';
import 'astrology_content_card.dart';
import 'astrology_content_lane_meta.dart';
import 'astrology_reading_presentation.dart';
import 'astrology_reference_theme_chips.dart';

class AstrologyReferenceSupportingInsights extends StatelessWidget {
  const AstrologyReferenceSupportingInsights({
    super.key,
    required this.reading,
    this.themeLabels = const <String>[],
  });

  final AstrologyDailyReading reading;
  final List<String> themeLabels;

  @override
  Widget build(BuildContext context) {
    final love = reading.loveBrief.trim();
    final career = reading.careerBrief.trim();
    final inner = AstrologyReadingPresentation.innerLane(reading).trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (love.isNotEmpty)
          AstrologyContentCard(
            kind: AstrologyContentLaneKind.love,
            body: love,
            index: 0,
            compact: true,
          ),
        if (career.isNotEmpty)
          AstrologyContentCard(
            kind: AstrologyContentLaneKind.work,
            body: career,
            index: 1,
            compact: true,
          ),
        if (inner.isNotEmpty)
          AstrologyContentCard(
            kind: AstrologyContentLaneKind.inner,
            body: inner,
            index: 2,
            compact: true,
          ),
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.s4),
          child: AstrologyReferenceThemeChips(labels: themeLabels),
        ),
      ],
    );
  }
}
