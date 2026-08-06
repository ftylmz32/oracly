import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';
import 'package:oracly_new/features/dream/models/dream_symbol.dart';
import 'package:oracly_new/features/dream/services/dream_pattern_service.dart';
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
  });

  group('DreamPatternService', () {
    const patterns = DreamPatternService();

    test('returns null when no genuine overlap', () {
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
        patterns.findConnection(current: current, previousDreams: const []),
        isNull,
      );
    });

    test('finds connection with two shared symbols', () {
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

      final match = patterns.findConnection(
        current: currentWithSymbols,
        previousDreams: [priorWithSymbols],
      );

      expect(match, isNotNull);
      expect(match!.sharedSymbols.length, greaterThanOrEqualTo(2));
    });
  });
}
