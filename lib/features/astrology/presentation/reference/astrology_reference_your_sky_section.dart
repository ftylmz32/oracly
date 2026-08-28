/// "SENİN GÖKYÜZÜN" — compact, personal, and based on the same supported reading.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/chamber_ornament_heading.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../content/astrology/models/astrology_content.dart';
import '../../copy/astrology_presentation_copy.dart';
import '../../models/astrology_daily_reading.dart';
import 'astrology_reading_presentation.dart';
import 'astrology_zodiac_illustration.dart';

class AstrologyReferenceYourSkySection extends StatelessWidget {
  const AstrologyReferenceYourSkySection({
    super.key,
    required this.sign,
    required this.reading,
  });

  final ZodiacSignContent sign;
  final AstrologyDailyReading reading;

  @override
  Widget build(BuildContext context) {
    final signName = OraclyL10n.t('zodiac.${sign.id}');
    final dateRange = OraclyL10n.t('zodiac.range.${sign.id}');
    final todayLead = AstrologyReadingPresentation.todayLead(reading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChamberOrnamentHeading(label: AstrologyPresentationCopy.yourSkyTitle),
        SizedBox(height: AppSpacing.s8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 1,
                  color: OraclyChrome.goldMuted.withValues(alpha: 0.55),
                ),
                boxShadow: [
                  BoxShadow(
                    color: OraclyChrome.gold.withValues(alpha: 0.12),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipOval(
                child: AstrologyZodiacIllustration(
                  signId: sign.id,
                  size: 56,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.s12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ReadingTypography.cardTitle(
                      color: OraclyChrome.cream.withValues(alpha: 0.96),
                    ).copyWith(fontSize: 16, letterSpacing: 1.2),
                  ),
                  SizedBox(height: AppSpacing.s4),
                  Text(
                    dateRange,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ReadingTypography.footnote(
                      color: OraclyChrome.cream.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.s12),
        Text(
          todayLead,
          textAlign: TextAlign.center,
          style: ReadingTypography.body(
            color: OraclyChrome.cream.withValues(alpha: 0.86),
          ),
        ),
      ],
    );
  }
}

