import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';
import 'package:oracly_new/features/birth_chart/models/chart_insight.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/birth_chart/services/birth_chart_persistence_validator.dart';
import 'package:oracly_new/features/birth_chart/services/chart_insight_generator.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';

void main() {
  group('NatalChartCalculator', () {
    const calculator = NatalChartCalculator();

    test('computes tropical sun sign from birth date only', () {
      final chart = calculator.calculate(
        BirthProfile(
          birthDate: DateTime(1995, 8, 15),
          birthPlace: 'İstanbul',
          birthTime: DateTime(1995, 8, 15, 14, 30),
          birthTimeKnown: true,
        ),
      );

      expect(chart.sun.sign, ZodiacSignId.leo);
      expect(chart.fidelity, ChartCalculationFidelity.tropicalSunSign);
      expect(chart.hasFullNatal, isFalse);
      expect(chart.moon, isNull);
      expect(chart.rising, isNull);
      expect(chart.planets, isEmpty);
      expect(chart.houses, isEmpty);
      expect(chart.aspects, isEmpty);
      expect(chart.precision, ChartPrecision.partialNoTime);
    });

    test('sun sign ignores birth time and location', () {
      final dated = DateTime(1995, 8, 15);
      final withExtras = calculator.calculate(
        BirthProfile(
          birthDate: dated,
          birthPlace: 'İstanbul',
          birthTime: DateTime(1995, 8, 15, 3, 12),
          birthTimeKnown: true,
          latitude: 41.01,
          longitude: 28.98,
        ),
      );
      final dateOnly = calculator.calculate(
        BirthProfile(
          birthDate: dated,
          birthPlace: '',
          birthTimeKnown: false,
        ),
      );

      expect(withExtras.sun.sign, ZodiacSignId.leo);
      expect(dateOnly.sun.sign, ZodiacSignId.leo);
      expect(withExtras.precision, ChartPrecision.partialNoTime);
      expect(withExtras.hasFullNatal, isFalse);
      expect(dateOnly.hasFullNatal, isFalse);
    });

    test('keeps profile when birth time is unknown', () {
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

    test('produces sun-based interpretations without fake natal claims', () {
      final base = calculator.calculate(
        BirthProfile(
          birthDate: DateTime(1992, 11, 10),
          birthPlace: 'İzmir',
          birthTime: DateTime(1992, 11, 10, 8, 0),
          birthTimeKnown: true,
        ),
      );

      final insights = generator.generate(base);

      expect(insights, isNotEmpty);
      expect(insights.first.kind, ChartInsightKind.bigThree);
      expect(insights.first.title, contains('Güneş'));
      expect(insights.first.title, contains('Akrep'));
      expect(insights.first.body, isNot(contains('kesin')));
      expect(
        insights.any((i) => i.kind == ChartInsightKind.lifeThemes),
        isTrue,
      );
    });
  });

  group('BirthChartPersistenceValidator', () {
    test('rejects calculator-only charts without insights', () {
      const calculator = NatalChartCalculator();
      final chart = calculator.calculate(
        BirthProfile(
          birthDate: DateTime(1990, 3, 25),
          birthPlace: 'Ankara',
          birthTimeKnown: false,
        ),
      );

      expect(BirthChartPersistenceValidator.isJourneyReady(chart), isFalse);
    });
  });
}
