import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/models/ritual_journal_metadata.dart';
import 'package:oracly_new/features/insights/services/personal_insight_engine.dart';

ReadingModel _reading({
  required String id,
  required String summary,
  required String card,
  List<String> tags = const [],
  DateTime? createdAt,
}) {
  return ReadingModel(
    id: id,
    cardId: 1,
    cardName: card,
    cardImageAsset: 'asset.png',
    spreadType: 'Tek Kart',
    aiSummary: summary,
    createdAt: createdAt ?? DateTime.now(),
    journal: RitualJournalMetadata(tags: tags),
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
    final readings = [
      _reading(
        id: '1',
        summary: 'Aşk yolculuğunda sabır.',
        card: 'The Lovers',
        tags: ['insight:love', 'insight:patience'],
      ),
      _reading(
        id: '2',
        summary: 'İlişkilerde değişim.',
        card: 'Death',
        tags: ['insight:love', 'insight:change'],
      ),
      _reading(
        id: '3',
        summary: 'Sabırla bekle.',
        card: 'Temperance',
        tags: ['insight:patience'],
      ),
    ];

    final report = PersonalInsightEngine.analyze(readings);
    expect(report.hasThemePattern, isTrue);
    expect(
      report.recurringThemes.map((e) => e.theme.id),
      contains('love'),
    );
  });

  test('monthly reflection uses uncertain observational language', () {
    final now = DateTime.now();
    final readings = List.generate(
      4,
      (i) => _reading(
        id: '$i',
        summary: 'Dönüşüm ve sabır bir arada.',
        card: 'Death',
        tags: ['insight:change', 'insight:patience'],
        createdAt: now.subtract(Duration(days: i)),
      ),
    );

    final report = PersonalInsightEngine.analyze(readings);
    expect(report.hasMonthlyReflection, isTrue);
    expect(report.monthlyReflection!.observation, contains('olabilir'));
    expect(report.monthlyReflection!.observation, isNot(contains('olacak')));
  });
}
