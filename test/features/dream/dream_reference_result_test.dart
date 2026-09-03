import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/models/dream_symbol.dart';
import 'package:oracly_new/features/dream/services/dream_reading_presentation.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('reference sections use real dream data only', () {
    const narrative = 'Yagmur sessizce dusuyordu, evin esiginde durdum.';
    final dream = Dream(
      id: 'd1',
      narrative: narrative,
      recordedAt: DateTime(2026, 8, 17),
      understanding: const DreamUnderstanding(
        symbols: [
          DreamSymbol(
            token: 'rain',
            label: 'Yagmur',
            kind: DreamSymbolKind.nature,
            observedContext: 'Yumusak bir gecis',
          ),
        ],
        emotions: ['Merak'],
        locations: const [],
        relationships: const [],
        recurringElements: const [],
        summary: 'Esik',
      ),
      insights: [
        DreamInsight(
          kind: DreamInsightKind.mainInterpretation,
          title: DreamCopy.interpretationTitle,
          body: 'Sahne sessiz bir esikte duruyor.',
        ),
        DreamInsight(
          kind: DreamInsightKind.emotionalMeaning,
          title: DreamCopy.emotionalMeaningTitle,
          body: 'Esik bir gecis hissini tutuyor.',
        ),
        DreamInsight(
          kind: DreamInsightKind.closingTakeaway,
          title: DreamCopy.optionalQuestionTitle,
          body: 'Bugun icin kucuk bir adim yeterli.',
        ),
      ],
    );

    expect(DreamReadingPresentation.story(dream), narrative);
    expect(
      DreamReadingPresentation.overallMeaning(dream),
      contains('esik'),
    );
    final symbols = DreamReadingPresentation.symbolRows(dream);
    expect(symbols, isNotEmpty);
    expect(symbols.first.label, 'Yagmur');
    expect(symbols.first.meaning, 'Yumusak bir gecis');
    expect(
      DreamReadingPresentation.emotionalReading(dream),
      contains('gecis'),
    );
    expect(DreamReadingPresentation.emotionalTags(dream), contains('#Merak'));
    expect(
      DreamReadingPresentation.reflectionQuote(dream),
      contains('adim'),
    );
    expect(
      DreamReadingPresentation.interpretation(dream),
      isNot(contains('Eski Ev')),
    );
  });

  test('empty symbol section hides when no data', () {
    final dream = Dream(
      id: 'd2',
      narrative: 'Kisa bir ruya',
      recordedAt: DateTime(2026, 8, 18),
      insights: const [],
    );
    expect(DreamReadingPresentation.symbolRows(dream), isEmpty);
  });
}
