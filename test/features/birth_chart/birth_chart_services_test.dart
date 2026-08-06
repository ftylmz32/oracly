import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/birth_chart/models/chart_insight.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/birth_chart/services/chart_insight_generator.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';

void main() {
  group('NatalChartCalculator', () {
    const calculator = NatalChartCalculator();

    test('computes sun sign from birth date', () {
      final chart = calculator.calculate(
        BirthProfile(
          birthDate: DateTime(1995, 8, 15),
          birthPlace: 'İstanbul',
          birthTime: DateTime(1995, 8, 15, 14, 30),
          birthTimeKnown: true,
        ),
      );

      expect(chart.sun.sign, ZodiacSignId.leo);
      expect(chart.moon.sign, isNotNull);
      expect(chart.rising, isNotNull);
      expect(chart.planets.length, 8);
      expect(chart.houses.length, 12);
      expect(chart.precision, ChartPrecision.full);
    });

    test('allows unknown birth time without blocking', () {
      final chart = calculator.calculate(
        BirthProfile(
          birthDate: DateTime(1990, 3, 25),
          birthPlace: 'Ankara',
          birthTimeKnown: false,
        ),
      );

      expect(chart.sun.sign, ZodiacSignId.aries);
      expect(chart.rising, isNull);
      expect(chart.precision, ChartPrecision.partialNoTime);
      expect(chart.insights, isEmpty);
    });
  });

  group('ChartInsightGenerator', () {
    const generator = ChartInsightGenerator();
    const calculator = NatalChartCalculator();

    test('produces eight phased insights in human language', () {
      final base = calculator.calculate(
        BirthProfile(
          birthDate: DateTime(1992, 11, 10),
          birthPlace: 'İzmir',
          birthTime: DateTime(1992, 11, 10, 8, 0),
          birthTimeKnown: true,
        ),
      );

      final insights = generator.generate(base);

      expect(insights.length, ChartInsightKind.values.length);
      expect(insights.first.kind, ChartInsightKind.bigThree);
      expect(insights.first.body, isNot(contains('kesin')));
      expect(insights.last.kind, ChartInsightKind.lifeThemes);
    });
  });
}
