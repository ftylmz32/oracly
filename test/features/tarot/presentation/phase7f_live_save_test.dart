/// Phase 7F — saveFromSession persists exact presentation provenance.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/repositories/history_repository.dart';
import 'package:oracly_new/core/domain/repositories/user_repository.dart';
import 'package:oracly_new/core/services/reading_service.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_mode.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';

class _MemHistory implements HistoryRepository {
  final List<ReadingModel> readings = [];
  @override
  Future<List<ReadingModel>> getReadings() async => List.of(readings);
  @override
  Future<void> saveReading(ReadingModel reading) async {
    readings.removeWhere((r) => r.id == reading.id);
    readings.add(reading);
  }
  @override
  Future<void> deleteReading(String id) async {
    readings.removeWhere((r) => r.id == id || r.sessionId == id);
  }
  @override
  Future<void> clearAll() async => readings.clear();
}

class _StubUser implements UserRepository {
  @override
  Future<void> ensureReadingCompletionMigration(
    List<String> existingHistoryIds,
  ) async {}

  @override
  Future<bool> recordReadingCompletion(String readingId) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReadingSession _session(TarotSpreadType spread) {
  final card = TarotCard(
    id: 0,
    name: 'The Fool',
    image: 'lib/assets/images/tarot/major_arcana/00_budala.png',
    arcana: TarotArcana.major,
    suit: TarotSuit.none,
    number: 0,
    summary: '',
    meaning: '',
    reversedMeaning: '',
    keywords: const [],
  );
  return ReadingSession(
    id: 'sess_7f_save',
    deckId: 'classic',
    spread: spread,
    intention: const TarotIntention(text: '', topic: null),
    shuffleSeed: 1,
    startedAt: DateTime.utc(2026, 9, 25),
    drawnCards: [
      TarotDrawnCard(card: card, positionIndex: 0, isReversed: false),
    ],
  );
}

void main() {
  test('Narrative V2 / AI / interpretation provenance saved exactly', () async {
    final history = _MemHistory();
    final service = ReadingService(history, _StubUser());
    final saved = await service.saveFromSession(
      session: _session(TarotSpreadType.threeCard),
      aiSummary: '## Summary\nLive body.',
      resultMode: ReadingResultMode.narrativeV2.name,
      interpretationSource: InterpretationSource.ai.name,
      deliveryKind: TarotReadingDeliveryKind.interpretation.name,
    );
    expect(saved, isNotNull);
    expect(saved!.resultMode, 'narrativeV2');
    expect(saved.interpretationSource, 'ai');
    expect(saved.deliveryKind, 'interpretation');
    expect(saved.cardName, 'The Fool');
    expect(saved.spreadType, 'threeCard');
  });

  test('legacy / local / recovery provenance saved exactly', () async {
    final history = _MemHistory();
    final service = ReadingService(history, _StubUser());
    final saved = await service.saveFromSession(
      session: _session(TarotSpreadType.sevenCard),
      aiSummary: '## Summary\nRecovery body.',
      resultMode: ReadingResultMode.legacy.name,
      interpretationSource: InterpretationSource.local.name,
      deliveryKind: TarotReadingDeliveryKind.recovery.name,
    );
    expect(saved!.resultMode, 'legacy');
    expect(saved.interpretationSource, 'local');
    expect(saved.deliveryKind, 'recovery');
  });
}
