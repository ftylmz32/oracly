/// Compact weekly overview - one short line per weekday.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_ornament_heading.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../data/astrology_weekly_copy.dart';
import 'astrology_reference_card_shell.dart';
import 'astrology_reference_tokens.dart';

class AstrologyReferenceWeeklySection extends StatelessWidget {
  const AstrologyReferenceWeeklySection({super.key, required this.days});

  final List<AstrologyWeekDay> days;

  static const title = 'Haftal\u0131k Bak\u0131\u015f';

  @override
  Widget build(BuildContext context) {
    return AstrologyReferenceCardShell(
      borderRadius: AstrologyReferenceTokens.dailyCardRadius,
      padding: AstrologyReferenceTokens.dailyCardPadding,
      premium: true,
      glowStrength: 1.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ChamberOrnamentHeading(label: title),
          SizedBox(height: AppSpacing.s8),
          for (final day in days)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(
                      day.label,
                      style: ReadingTypography.label(
                        color: OraclyChrome.goldLight.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      day.text,
                      style: ReadingTypography.bodySmall(
                        color: OraclyChrome.cream.withValues(
                          alpha: CraftsmanshipRhythm.secondaryInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
