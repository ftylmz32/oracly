import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';
import 'package:oracly_new/features/dream/models/dream_symbol.dart';
import 'package:oracly_new/features/dream/history/dream_history_builder.dart';
import 'package:oracly_new/features/dream/history/dream_history_evidence.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';

void main() {
  group('DreamUnderstandingService', () {
    final service = DreamUnderstandingService();

    test('extracts symbols and locations without interpretation tone', () {
      final result = service.build(
        narrative: 'Evde kedimle deniz kenarında yürüdüm, annem de vardı.',
        selectedEmotions: [DreamEmotion(id: DreamEmotionId.peaceful)],
      );

      expect(result.symbols.map((s) => s.label.toLowerCase()), isNotEmpty);
      expect(result.locations, contains('Ev'));
      expect(result.relationships.map((r) => r.label), contains('Anne'));
      expect(result.emotions, contains('Huzurlu'));
      expect(result.summary, isNot(contains('kesin')));
    });

    test('"saat" does not become the animal "at"', () {
      // Regression for a real production defect: naive substring matching
      // found the lexicon token "at" (horse) inside "saat" (clock/hour),
      // showing a horse symbol for a dream that never mentioned one.
      final result = service.build(
        narrative: 'İstasyonda büyük, durmuş bir saat vardı.',
      );
      final labels = result.symbols.map((s) => s.label.toLowerCase()).toSet();
      expect(labels, isNot(contains('at')));
    });

    test('"ray"/"raylar"/"rayların" does not become the symbol "ay"', () {
      // Regression for the same class of defect: "ay" (moon) matched inside
      // "ray"/"raylar"/"rayların" (rail/rails/of-the-rails).
      for (final narrative in [
        'Raylar arasında ince bir su akıyordu.',
        'Rayların arasında ince bir su vardı.',
        'İnce bir ray gördüm.',
      ]) {
        final result = service.build(narrative: narrative);
        final labels =
            result.symbols.map((s) => s.label.toLowerCase()).toSet();
        expect(labels, isNot(contains('ay')), reason: narrative);
      }
    });

    test('a real standalone mention of "at" or "ay" is still detected', () {
      // The fix must reject substring collisions without rejecting genuine,
      // real word-boundary matches of the same short tokens.
      final horse = service.build(narrative: 'Yanımda kahverengi bir at duruyordu.');
      expect(
        horse.symbols.map((s) => s.label.toLowerCase()),
        contains('at'),
      );
      final moon = service.build(narrative: 'Gökyüzünde büyük bir ay vardı.');
      expect(
        moon.symbols.map((s) => s.label.toLowerCase()),
        contains('ay'),
      );
    });

    test('genuine symbols in a multi-element narrative are retained', () {
      final result = service.build(
        narrative:
            'Eski tren istasyonunda tüm lambalar yanıyordu. Rayların '
            'arasında ince bir su vardı, suyun içinde bir pusula duruyordu. '
            'Büyük beyaz bir kuş gördüm.',
      );
      final labels = result.symbols.map((s) => s.label.toLowerCase()).toSet();
      expect(labels, contains('su'));
      expect(labels, contains('beyaz'));
      expect(labels, contains('kuş'));
      expect(result.locations, contains('Tren'));
      expect(labels, isNot(contains('at')));
      expect(labels, isNot(contains('ay')));
    });
  });

  group('DreamHistoryBuilder', () {
    test('is empty when no prior dream exists', () {
      final current = Dream(
        id: 'a',
        narrative: 'uçtum',
        recordedAt: DateTime.now(),
        understanding: const DreamUnderstanding(
          symbols: [],
          emotions: [],
          locations: [],
          relationships: [],
          recurringElements: [],
          summary: 'test',
        ),
      );

      expect(
        DreamHistoryBuilder.build(
          current: current,
          saved: const [],
          language: 'tr',
        ).isEmpty,
        isTrue,
      );
    });

    test('one prior dream sharing two symbols is seen before', () {
      final priorWithSymbols = Dream(
        id: 'old',
        narrative: 'deniz kedisi',
        recordedAt: DateTime(2024, 1, 1),
        understanding: DreamUnderstanding(
          symbols: [
            const DreamSymbol(
              token: 'deniz',
              label: 'Deniz',
              kind: DreamSymbolKind.place,
            ),
            const DreamSymbol(
              token: 'kedi',
              label: 'Kedi',
              kind: DreamSymbolKind.animal,
            ),
          ],
          emotions: const [],
          locations: const [],
          relationships: const [],
          recurringElements: const [],
          summary: 'old',
        ),
      );

      final currentWithSymbols = Dream(
        id: 'new',
        narrative: 'deniz kedisi tekrar',
        recordedAt: DateTime.now(),
        understanding: DreamUnderstanding(
          symbols: priorWithSymbols.understanding!.symbols,
          emotions: const [],
          locations: const [],
          relationships: const [],
          recurringElements: const [],
          summary: 'new',
        ),
      );

      final history = DreamHistoryBuilder.build(
        current: currentWithSymbols,
        saved: [priorWithSymbols],
        language: 'tr',
      );

      expect(history.evidence, hasLength(2));
      expect(
        history.evidence.map((e) => e.level),
        everyElement(DreamRecurrenceLevel.seenBefore),
      );
    });
  });
}
