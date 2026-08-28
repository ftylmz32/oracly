/// Generated birth-chart user-facing copy respects session locale.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/services/chart_insight_generator.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';

void main() {
  const calculator = NatalChartCalculator();
  const generator = ChartInsightGenerator();

  BirthProfile profile() => BirthProfile(
        birthDate: DateTime(1992, 11, 10),
        birthPlace: 'Izmir',
        birthTimeKnown: false,
      );

  test('TR EN RU generated result presentation differs by locale', () {
    OraclyL10n.bind('tr');
    final trChart = calculator.calculate(profile());
    final trInsight = generator.generate(trChart).first;
    expect(trInsight.title, contains(OraclyL10n.t('birth.sun')));
    expect(trInsight.title, contains(OraclyL10n.t('zodiac.scorpio')));
    expect(trChart.dominantEnergy.label, contains(OraclyL10n.t('birth.element.water')));

    OraclyL10n.bind('en');
    final enChart = calculator.calculate(profile());
    final enInsight = generator.generate(enChart).first;
    expect(enInsight.title, contains(OraclyL10n.t('birth.sun')));
    expect(enInsight.title, contains(OraclyL10n.t('zodiac.scorpio')));
    expect(enChart.dominantEnergy.label, contains(OraclyL10n.t('birth.element.water')));
    expect(enInsight.body.toLowerCase(), isNot(contains('gunesi')));
    expect(enInsight.body, isNot(contains(OraclyL10n.t('birth.sun', languageCode: 'tr'))));

    OraclyL10n.bind('ru');
    final ruChart = calculator.calculate(profile());
    final ruInsight = generator.generate(ruChart).first;
    expect(ruInsight.title, contains(OraclyL10n.t('birth.sun')));
    expect(ruInsight.title, contains(OraclyL10n.t('zodiac.scorpio')));
    expect(ruChart.dominantEnergy.summary, isNot(contains(OraclyL10n.t('birth.sun', languageCode: 'tr'))));
  });
}
