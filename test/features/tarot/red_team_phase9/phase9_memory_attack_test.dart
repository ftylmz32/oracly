/// Phase 9 — memory / recurrence integration attacks.
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_card_recurrence_engine.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_theme_recurrence_engine.dart';

import '../narrative_history/tarot_history_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = nowFixed;

  test('card recurrence ignores foreign connectedMemories noise', () {
    final base = baseRequest();
    final out = TarotCardRecurrenceEngine.build(
      base: base,
      history: TarotHistoricalSnapshot(
        tarotReadings: [
          histReading(
            readingId: 'h1',
            at: now.subtract(const Duration(days: 1)),
            cardId: major00,
          ),
        ],
        connectedMemories: [
          connectedMemory(
            sourceId: 'noise',
            sourceType: TarotConnectedMemorySourceType.coffee,
            at: now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
      currentOwnerId: null,
      now: now,
    );
    expect(out.recurringCards.single.occurrenceCount, 1);
  });

  test('theme recurrence does not invent support from empty history', () {
    final base = baseRequest();
    final out = TarotThemeRecurrenceEngine.build(
      base: base,
      history: TarotHistoricalSnapshot(
        tarotReadings: const [],
        connectedMemories: const [],
      ),
      now: now,
    );
    expect(out, isEmpty);
  });

  test('owner A history does not feed owner B recurrence', () {
    final base = baseRequest();
    final out = TarotCardRecurrenceEngine.build(
      base: base,
      history: TarotHistoricalSnapshot(
        tarotReadings: [
          histReading(
            readingId: 'h_a',
            at: now.subtract(const Duration(days: 2)),
            cardId: major00,
            ownerId: 'A',
          ),
        ],
        connectedMemories: const [],
      ),
      currentOwnerId: 'B',
      now: now,
    );
    expect(out.recurringCards, isEmpty);
  });
}
