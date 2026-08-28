/// Saved Yıldızname overview — only calculated placements, no invented sky.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../../../features/ai/oracle_conversation/widgets/or_ask_button.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../copy/birth_chart_copy.dart';
import '../../models/birth_chart.dart';
import '../../models/chart_insight.dart';
import '../../services/chart_insight_locale.dart';
import 'birth_chart_identity_card.dart';
import 'birth_chart_placement_card.dart';
import 'birth_chart_result_lists.dart';

class BirthChartResultView extends StatelessWidget {
  const BirthChartResultView({
    super.key,
    required this.chart,
    this.closingMessage,
    this.onUpdateInfo,
  });

  final BirthChart chart;
  final String? closingMessage;
  final VoidCallback? onUpdateInfo;

  @override
  Widget build(BuildContext context) {
    final showNatal = chart.hasFullNatal;
    final sunLabel = ChartInsightLocale.signName(chart.sun.sign);
    final summary = ChartInsightLocale.fill('birth.result.summary', {
      'sign': sunLabel,
      'energy': chart.dominantEnergy.label.toLowerCase(),
      'ephemeris': BirthChartCopy.ephemerisNote,
    });
    final strong = chart.lifeThemes.isEmpty
        ? ChartInsightLocale.fill('birth.result.strong_fallback', {
            'sign': sunLabel,
          })
        : chart.lifeThemes.map((t) => '${t.title}: ${t.body}').join('\n\n');
    final notable = chart.dominantEnergy.summary;
    final interpretation = _coreBody(chart) ?? summary;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        0,
        AppSpacing.s8,
        0,
        AppLayout.scrollBottomInset(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BirthChartIdentityCard(chart: chart),
          SizedBox(height: OraclyChrome.sectionGap),
          _block(BirthChartCopy.summaryTitle, summary),
          SizedBox(height: AppSpacing.s8),
          _block(BirthChartCopy.strongThemesTitle, strong),
          SizedBox(height: AppSpacing.s8),
          _block(BirthChartCopy.notableThemesTitle, notable),
          SizedBox(height: AppSpacing.s8),
          _block(BirthChartCopy.resultInterpretation, interpretation),
          if (showNatal && chart.planets.isNotEmpty) ...[
            SizedBox(height: OraclyChrome.sectionGap),
            BirthChartPlanetsList(planets: chart.planets),
          ],
          if (showNatal && chart.houses.isNotEmpty) ...[
            SizedBox(height: OraclyChrome.sectionGap),
            BirthChartHousesList(houses: chart.houses),
          ],
          if (showNatal && chart.aspects.isNotEmpty) ...[
            SizedBox(height: OraclyChrome.sectionGap),
            BirthChartAspectsList(aspects: chart.aspects),
          ],
          if (!showNatal) ...[
            SizedBox(height: OraclyChrome.sectionGap),
            const BirthChartEphemerisNote(),
          ],
          SizedBox(height: OraclyChrome.sectionGap),
          Text(
            closingMessage ?? BirthChartCopy.closingNote,
            style: ReadingTypography.closing(),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: OraclyChrome.sectionGap),
          OrAskButton(
            readingContext: OracleReadingContextSources.birthChart(
              id: chart.id,
              sunLabel: sunLabel,
              interpretation: interpretation,
              profile: chart.profile,
              summary: summary,
              strongThemes: strong,
              notableThemes: notable,
              placements: showNatal
                  ? [
                      if (chart.moon != null)
                        ChartInsightLocale.fill('birth.placement.moon', {
                          'sign': ChartInsightLocale.signName(
                            chart.moon!.sign,
                          ),
                        }),
                      if (chart.rising != null)
                        ChartInsightLocale.fill('birth.placement.rising', {
                          'sign': ChartInsightLocale.signName(
                            chart.rising!.sign,
                          ),
                        }),
                      ...chart.planets.map(
                        (p) => ChartInsightLocale.fill(
                          'birth.placement.planet',
                          {
                            'planet': p.id.labeled(OraclyL10n.code),
                            'sign': ChartInsightLocale.signName(p.sign),
                          },
                        ),
                      ),
                    ]
                  : const [],
            ),
          ),
          if (onUpdateInfo != null) ...[
            SizedBox(height: OraclyChrome.sectionGap),
            OraclyButton(
              text: BirthChartCopy.updateBirthInfo,
              type: OraclyButtonType.ghost,
              isExpanded: true,
              onPressed: onUpdateInfo,
            ),
          ],
        ],
      ),
    );
  }

  static String? _coreBody(BirthChart chart) {
    for (final insight in chart.insights) {
      if (insight.kind == ChartInsightKind.corePersonality) return insight.body;
    }
    return null;
  }

  Widget _block(String title, String body) {
    return BirthChartPlacementCard(
      insight: ChartInsight(
        kind: ChartInsightKind.lifeThemes,
        title: title,
        body: body,
      ),
    );
  }
}
