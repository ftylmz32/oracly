/// Ask-OR handoff payload helpers for the birth chart result.
library;

import '../../../../core/l10n/l10n.dart';
import '../../models/birth_chart.dart';
import '../../services/chart_insight_locale.dart';

abstract final class BirthChartResultAsk {
  BirthChartResultAsk._();

  static List<String> placements(BirthChart chart, {required bool showNatal}) {
    if (!showNatal) return const [];
    return [
      if (chart.moon != null)
        ChartInsightLocale.fill('birth.placement.moon', {
          'sign': ChartInsightLocale.signName(chart.moon!.sign),
        }),
      if (chart.rising != null)
        ChartInsightLocale.fill('birth.placement.rising', {
          'sign': ChartInsightLocale.signName(chart.rising!.sign),
        }),
      ...chart.planets.map(
        (p) => ChartInsightLocale.fill('birth.placement.planet', {
          'planet': p.id.labeled(OraclyL10n.code),
          'sign': ChartInsightLocale.signName(p.sign),
        }),
      ),
    ];
  }
}
