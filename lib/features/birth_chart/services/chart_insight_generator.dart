/// Translates known placements into calm, locale-aware interpretations.
library;

import '../../../core/l10n/l10n.dart';
import '../copy/birth_chart_copy.dart';
import '../models/birth_chart.dart';
import '../models/chart_insight.dart';
import '../models/life_theme.dart';
import '../models/zodiac_sign_id.dart';
import 'chart_insight_locale.dart';

class ChartInsightGenerator {
  const ChartInsightGenerator();

  List<ChartInsight> generate(BirthChart chart) {
    final sun = chart.sun.sign;
    final moon = chart.hasFullNatal ? chart.moon?.sign : null;
    final rising = chart.hasFullNatal ? chart.rising?.sign : null;
    return [
      _sunPlacement(sun),
      if (moon != null) _moonPlacement(moon),
      if (rising != null) _risingPlacement(rising),
      _corePersonality(sun, moon, rising),
      _lifeThemesInsight(chart),
    ];
  }

  List<LifeTheme> lifeThemes(BirthChart chart) {
    final sun = chart.sun.sign;
    final name = ChartInsightLocale.signName(sun);
    final traits = ChartInsightLocale.joinAnd(ChartInsightLocale.traits(sun));
    return [
      LifeTheme(
        id: 'identity',
        title: OraclyL10n.t('birth.theme.identity'),
        body: ChartInsightLocale.fill('birth.theme.identity_body', {
          'sign': name,
          'traits': traits,
        }),
      ),
      LifeTheme(
        id: 'element',
        title: chart.dominantEnergy.label,
        body: chart.dominantEnergy.summary,
      ),
    ];
  }

  ChartInsight _sunPlacement(ZodiacSignId sun) {
    final name = ChartInsightLocale.signName(sun);
    final traits = ChartInsightLocale.joinAnd(ChartInsightLocale.traits(sun));
    return ChartInsight(
      kind: ChartInsightKind.bigThree,
      title: '${BirthChartCopy.sunLabel} — $name',
      body: ChartInsightLocale.fill('birth.insight.sun_body', {
        'sign': name,
        'traits': traits,
        'glossary': BirthChartCopy.sunGlossary,
      }),
      glossaryTerm: BirthChartCopy.sunLabel,
      glossaryExplanation: BirthChartCopy.sunGlossary,
    );
  }

  ChartInsight _moonPlacement(ZodiacSignId moon) {
    final name = ChartInsightLocale.signName(moon);
    final trait = ChartInsightLocale.traits(moon).first;
    return ChartInsight(
      kind: ChartInsightKind.emotionalPatterns,
      title: '${BirthChartCopy.moonLabel} — $name',
      body: ChartInsightLocale.fill('birth.insight.moon_body', {
        'sign': name,
        'trait': trait,
        'glossary': BirthChartCopy.moonGlossary,
      }),
      glossaryTerm: BirthChartCopy.moonLabel,
      glossaryExplanation: BirthChartCopy.moonGlossary,
    );
  }

  ChartInsight _risingPlacement(ZodiacSignId rising) {
    final name = ChartInsightLocale.signName(rising);
    final trait = ChartInsightLocale.traits(rising).first;
    return ChartInsight(
      kind: ChartInsightKind.strengths,
      title: '${BirthChartCopy.risingLabel} — $name',
      body: ChartInsightLocale.fill('birth.insight.rising_body', {
        'sign': name,
        'trait': trait,
        'glossary': BirthChartCopy.risingGlossary,
      }),
      glossaryTerm: BirthChartCopy.risingLabel,
      glossaryExplanation: BirthChartCopy.risingGlossary,
    );
  }

  ChartInsight _corePersonality(
    ZodiacSignId sun,
    ZodiacSignId? moon,
    ZodiacSignId? rising,
  ) {
    final sunName = ChartInsightLocale.signName(sun);
    final traits = ChartInsightLocale.joinAnd(ChartInsightLocale.traits(sun));
    final parts = <String>[
      ChartInsightLocale.fill('birth.insight.core_sun', {
        'sign': sunName,
        'traits': traits,
      }),
      ChartInsightLocale.career(sun),
    ];
    if (moon != null) {
      parts.add(
        ChartInsightLocale.fill('birth.insight.core_moon', {
          'sign': ChartInsightLocale.signName(moon),
          'trait': ChartInsightLocale.traits(moon).first,
        }),
      );
    }
    if (rising != null) {
      parts.add(
        ChartInsightLocale.fill('birth.insight.core_rising', {
          'sign': ChartInsightLocale.signName(rising),
          'trait': ChartInsightLocale.traits(rising).first,
        }),
      );
    }
    return ChartInsight(
      kind: ChartInsightKind.corePersonality,
      title: BirthChartCopy.corePersonalityTitle,
      body: parts.join('\n\n'),
    );
  }

  ChartInsight _lifeThemesInsight(BirthChart chart) {
    final themes = lifeThemes(chart);
    return ChartInsight(
      kind: ChartInsightKind.lifeThemes,
      title: BirthChartCopy.lifeThemesTitle,
      body: themes.map((t) => '${t.title}\n${t.body}').join('\n\n'),
    );
  }
}
