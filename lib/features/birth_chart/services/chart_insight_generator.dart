/// SPRINT-002 — Translates chart data into human insights.
library;

import '../../../features/content/astrology/data/astrology_content_catalogue.dart';
import '../../../features/content/astrology/models/astrology_content.dart';
import '../copy/birth_chart_copy.dart';
import '../models/birth_chart.dart';
import '../models/chart_insight.dart';
import '../models/life_theme.dart';
import '../models/zodiac_sign_id.dart';

class ChartInsightGenerator {
  const ChartInsightGenerator();

  List<ChartInsight> generate(BirthChart chart) {
    final sunContent = _content(chart.sun.sign);
    final moonContent = _content(chart.moon.sign);
    final risingContent =
        chart.rising != null ? _content(chart.rising!.sign) : null;

    return [
      _bigThree(chart, sunContent, moonContent, risingContent),
      _corePersonality(sunContent, moonContent, risingContent),
      _strengths(sunContent, moonContent),
      _growthAreas(sunContent, moonContent),
      _relationships(sunContent, moonContent),
      _career(sunContent, chart),
      _emotional(moonContent, chart),
      _lifeThemesInsight(chart),
    ];
  }

  List<LifeTheme> lifeThemes(BirthChart chart) {
    final sun = _content(chart.sun.sign);
    return [
      LifeTheme(
        id: 'identity',
        title: 'Kimlik',
        body:
            '${sun.nameTr} Güneşin, ${sun.traits.take(2).join(' ve ').toLowerCase()} '
            'yanlarını öne çıkarmayı sevebilir.',
      ),
      LifeTheme(
        id: 'element',
        title: chart.dominantEnergy.label,
        body: chart.dominantEnergy.summary,
      ),
      if (chart.aspects.isNotEmpty)
        LifeTheme(
          id: 'aspect',
          title: 'İç gerilim ve denge',
          body:
              'Haritanda ${chart.aspects.first.type.labelTr} açısı '
              'farklı ihtiyaçların aynı anda konuştuğunu düşündürebilir — '
              'bu bir çatışma değil, denge arayışı olabilir.',
        ),
    ];
  }

  ChartInsight _bigThree(
    BirthChart chart,
    ZodiacSignContent sun,
    ZodiacSignContent moon,
    ZodiacSignContent? rising,
  ) {
    final risingLine = rising != null
        ? 'Yükselen ${rising.nameTr} — dışarıdan ${rising.traits.first.toLowerCase()} bir izlenim bırakabilirsin.'
        : BirthChartCopy.risingUnavailable;

    return ChartInsight(
      kind: ChartInsightKind.bigThree,
      title: BirthChartCopy.bigThreeTitle,
      body:
          'Güneş ${sun.nameTr}: ${sun.traits.take(2).join(', ').toLowerCase()}.\n'
          'Ay ${moon.nameTr}: duygusal dünyanda ${moon.traits.first.toLowerCase()} bir ton.\n'
          '$risingLine',
      glossaryTerm: BirthChartCopy.sunLabel,
      glossaryExplanation: BirthChartCopy.sunGlossary,
    );
  }

  ChartInsight _corePersonality(
    ZodiacSignContent sun,
    ZodiacSignContent moon,
    ZodiacSignContent? rising,
  ) {
    final parts = <String>[
      'Özün ${sun.nameTr} enerjisiyle ${sun.traits.join(', ').toLowerCase()} bir tını taşıyor olabilir.',
      'Ay ${moon.nameTr} konumun, dinlenmeye ihtiyaç duyduğunda ${moon.traits.first.toLowerCase()} bir ton arayabileceğini düşündürür.',
    ];
    if (rising != null) {
      parts.add(
        'Yükselen ${rising.nameTr}, tanışıldığında ${rising.traits.first.toLowerCase()} bir izlenim bırakman mümkün.',
      );
    }

    return ChartInsight(
      kind: ChartInsightKind.corePersonality,
      title: BirthChartCopy.corePersonalityTitle,
      body: parts.join('\n\n'),
    );
  }

  ChartInsight _strengths(
    ZodiacSignContent sun,
    ZodiacSignContent moon,
  ) {
    final strengths = {...sun.strengths, ...moon.strengths}.take(4).toList();
    return ChartInsight(
      kind: ChartInsightKind.strengths,
      title: BirthChartCopy.strengthsTitle,
      body: strengths.map((s) => '• $s').join('\n'),
    );
  }

  ChartInsight _growthAreas(
    ZodiacSignContent sun,
    ZodiacSignContent moon,
  ) {
    final areas = {...sun.weaknesses, ...moon.weaknesses}.take(3).toList();
    return ChartInsight(
      kind: ChartInsightKind.growthAreas,
      title: BirthChartCopy.growthTitle,
      body:
          'Gelişim alanları zayıflık değil; farkındalık davetidir.\n'
          '${areas.map((a) => '• $a').join('\n')}',
    );
  }

  ChartInsight _relationships(
    ZodiacSignContent sun,
    ZodiacSignContent moon,
  ) {
    return ChartInsight(
      kind: ChartInsightKind.relationships,
      title: BirthChartCopy.relationshipsTitle,
      body:
          '${sun.loveStyle}\n\n'
          'Duygusal ihtiyaçlarında Ay ${moon.nameTr} tonu: '
          '${moon.loveStyle}',
    );
  }

  ChartInsight _career(ZodiacSignContent sun, BirthChart chart) {
    return ChartInsight(
      kind: ChartInsightKind.careerPurpose,
      title: BirthChartCopy.careerTitle,
      body:
          '${sun.careerStyle}\n\n'
          'Haritandaki ${chart.dominantEnergy.label} imzası, '
          'hangi ortamlarda kendini daha doğal hissettiğine dair ipuçları verebilir.',
    );
  }

  ChartInsight _emotional(ZodiacSignContent moon, BirthChart chart) {
    return ChartInsight(
      kind: ChartInsightKind.emotionalPatterns,
      title: BirthChartCopy.emotionalTitle,
      body:
          'Ay ${moon.nameTr}: ${moon.traits.join(', ').toLowerCase()}.\n\n'
          'Duygusal denge haritanda ${chart.elementBalance.dominantLabelTr()} '
          'elementinin ağırlık kazanmasıyla ilişkilendirilebilir — '
          'bu bir etiket değil, gözlem.',
      glossaryTerm: BirthChartCopy.moonLabel,
      glossaryExplanation: BirthChartCopy.moonGlossary,
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

  ZodiacSignContent _content(ZodiacSignId sign) {
    return AstrologyContentCatalogue.signById(sign.id) ??
        AstrologyContentCatalogue.signs.first;
  }
}
