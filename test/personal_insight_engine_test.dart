import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/models/ritual_journal_metadata.dart';
import 'package:oracly_new/features/insights/services/personal_insight_engine.dart';

ReadingModel _reading({
  required String id,
  required String summary,
  required String card,
  List<String> tags = const [],
  required DateTime createdAt,
}) {
  return ReadingModel(
    id: id,
    cardId: 1,
    cardName: card,
    cardImageAsset: 'asset.png',
    spreadType: 'Tek Kart',
    aiSummary: summary,
    createdAt: createdAt,
    journal: RitualJournalMetadata(tags: tags),
  );
}

List<ReadingModel> _monthReadings(DateTime asOf, {required int count}) {
  return List.generate(
    count,
    (i) => _reading(
      id: '$i',
      summary: 'Dönüşüm ve sabır bir arada.',
      card: 'Death',
      tags: ['insight:change', 'insight:patience'],
      createdAt: DateTime(asOf.year, asOf.month, 1 + (i % 20), 12),
    ),
  );
}

void main() {
  test('tagsForReading stores insight theme ids locally', () {
    final tags = PersonalInsightEngine.tagsForReading(
      aiSummary: 'Aşk ve ilişkilerde sabır önemli.',
      cardName: 'The Lovers',
    );
    expect(tags, contains('insight:love'));
    expect(tags, contains('insight:patience'));
  });

  test('analyze finds recurring themes after enough readings', () {
    final asOf = DateTime(2026, 8, 15);
    final readings = [
      _reading(
        id: '1',
        summary: 'Aşk yolculuğunda sabır.',
        card: 'The Lovers',
        tags: ['insight:love', 'insight:patience'],
        createdAt: asOf.subtract(const Duration(days: 2)),
      ),
      _reading(
        id: '2',
        summary: 'İlişkilerde değişim.',
        card: 'Death',
        tags: ['insight:love', 'insight:change'],
        createdAt: asOf.subtract(const Duration(days: 1)),
      ),
      _reading(
        id: '3',
        summary: 'Sabırla bekle.',
        card: 'Temperance',
        tags: ['insight:patience'],
        createdAt: asOf,
      ),
    ];

    final report = PersonalInsightEngine.analyze(readings, asOf: asOf);
    expect(report.hasThemePattern, isTrue);
    expect(report.recurringThemes.map((e) => e.theme.id), contains('love'));
  });

  test('monthly reflection uses uncertain observational language', () {
    final asOf = DateTime(2026, 8, 20, 12);
    final readings = _monthReadings(asOf, count: 4);

    final report = PersonalInsightEngine.analyze(readings, asOf: asOf);
    expect(report.hasMonthlyReflection, isTrue);
    expect(report.monthlyReflection!.observation, contains('olabilir'));
    expect(report.monthlyReflection!.observation, isNot(contains('olacak')));
  });

  test('insufficient history in month yields no monthly reflection', () {
    final asOf = DateTime(2026, 8, 20, 12);
    final readings = _monthReadings(asOf, count: 3);

    final report = PersonalInsightEngine.analyze(readings, asOf: asOf);
    expect(report.hasThemePattern, isTrue);
    expect(report.hasMonthlyReflection, isFalse);
  });

  test('month transition excludes prior-month readings', () {
    final asOf = DateTime(2026, 9, 2, 12);
    final readings = [
      ..._monthReadings(DateTime(2026, 8, 28), count: 4),
      ..._monthReadings(asOf, count: 2),
    ];

    final report = PersonalInsightEngine.analyze(readings, asOf: asOf);
    expect(report.hasMonthlyReflection, isFalse);
  });

  test('asOf pins month window independent of wall clock', () {
    final asOf = DateTime(2025, 1, 31, 23, 30);
    final readings = _monthReadings(asOf, count: 4);

    final report = PersonalInsightEngine.analyze(readings, asOf: asOf);
    expect(report.hasMonthlyReflection, isTrue);
    expect(report.monthlyReflection!.readingCount, 4);
  });
}
