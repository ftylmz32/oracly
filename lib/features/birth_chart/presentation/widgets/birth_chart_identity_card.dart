/// Yıldızname identity — large celestial hero + sun-sign honesty.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_art_frame.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/copy/preview_capability_copy.dart';
import '../../../../core/l10n/oracly_format.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../copy/birth_chart_copy.dart';
import '../../data/birth_chart_cities.dart';
import '../../models/birth_chart.dart';
import '../../services/chart_insight_locale.dart';

class BirthChartIdentityCard extends StatelessWidget {
  const BirthChartIdentityCard({super.key, required this.chart});

  final BirthChart chart;

  @override
  Widget build(BuildContext context) {
    final p = chart.profile;
    final parts = <String>[OraclyFormat.dateNumeric(p.birthDate)];
    if (p.hasKnownTime) {
      parts.add(OraclyFormat.time(p.birthTime!));
    }
    final place = p.birthPlace.trim();
    if (place.isNotEmpty) {
      parts.add(BirthChartCities.byName(place)?.label() ?? place);
    }
    final unusedStored = p.hasKnownTime || place.isNotEmpty;
    final sun = ChartInsightLocale.signName(chart.sun.sign);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: OraclyArtFrame(
            assetPath: AppAssets.yildiznameHero,
            width: 236,
            height: 236,
            borderRadius: OraclyChrome.heroRadius,
            padding: EdgeInsets.all(4),
            semanticsLabel: BirthChartCopy.screenTitle,
          ),
        ),
        SizedBox(height: AppSpacing.s12),
        OraclyGlassCard(
          padding: OraclyChrome.cardPadding,
          borderRadius: OraclyChrome.cardRadius,
          premium: true,
          glowStrength: 1.1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: OraclyChrome.gold.withValues(alpha: 0.55),
                      ),
                    ),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.wb_sunny_rounded,
                        size: 18,
                        color: OraclyChrome.goldLight.withValues(alpha: 0.94),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          BirthChartCopy.sectionYourChart,
                          style: OraclyChrome.sectionLabel(size: 11),
                        ),
                        Text(
                          sun,
                          style: OraclyChrome.engravedTitle(size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s8),
              Text(
                parts.join(' · '),
                style: OraclyChrome.bodySecondary(size: 12).copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              SizedBox(height: AppSpacing.s8),
              Text(
                PreviewCapabilityCopy.starMapNote,
                style: OraclyChrome.bodySecondary(size: 11).copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                  height: 1.28,
                ),
              ),
              if (unusedStored) ...[
                SizedBox(height: AppSpacing.s4),
                Text(
                  BirthChartCopy.storedNotUsedNote,
                  style: OraclyChrome.bodySecondary(size: 11),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
