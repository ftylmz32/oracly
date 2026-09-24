/// Phase 6E — history enrichment, Crossroads hist occurrence, privacy wipe.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_connected_memory_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_classical_shadow.dart';
import 'package:oracly_new/features/tarot/narrative/transport/narrative_tarot_wire_contract.dart';

import '../narrative_history/tarot_history_test_support.dart';
import 'narrative_shadow_test_support.dart';

void main() {
  final now = nowFixed;

  test('history enrichment + Crossroads occurrence + privacy', () {
    final session = relationshipSingleSession();
    final history = TarotHistoricalSnapshot(
      tarotReadings: [
        histReading(
          readingId: 'h1',
          at: now.subtract(const Duration(days: 3)),
          cardId: major00,
          questionKind: QuestionKind.relationship,
          topicId: 'love',
          intentionSummary: 'relationship loyalty partner stay',
        ),
        histReading(
          readingId: 'h2',
          at: now.subtract(const Duration(days: 5)),
          cardId: major00,
          questionKind: QuestionKind.relationship,
          topicId: 'love',
          intentionSummary: 'relationship loyalty partner stay',
        ),
        histReading(
          readingId: 'h_cr',
          at: now.subtract(const Duration(days: 4)),
          spreadId: 'signature.crossroads',
          cardId: major00,
          positionKey: 'option_a',
          positionIndex: 0,
          questionKind: QuestionKind.decision,
          intentionSummary: 'crossroads path honesty',
        ),
      ],
      connectedMemories: [
        connectedMemory(
          sourceId: 'c1',
          sourceType: TarotConnectedMemorySourceType.coffee,
          at: now.subtract(const Duration(days: 2)),
          themeIds: const ['ilişki'],
          summary: 'shared loyalty partner reflection coffee',
        ),
        connectedMemory(
          sourceId: 'd1',
          sourceType: TarotConnectedMemorySourceType.dream,
          at: now.subtract(const Duration(days: 4)),
          themeIds: const ['ilişki'],
          summary: 'shared loyalty partner reflection dream',
        ),
      ],
    );

    final ok = NarrativeTarotClassicalShadow.evaluate(
      session: session,
      readingId: 'read_hist_6e',
      languageCode: 'en',
      history: history,
      now: now,
    );
    expect(ok.isPass, isTrue);
    final base = ok.baseNarrativeRequest!;
    final finalReq = ok.finalNarrativeRequest!;
    expect(finalReq.sessionId, base.sessionId);
    expect(finalReq.readingId, base.readingId);
    expect(finalReq.languageCode, base.languageCode);
    expect(finalReq.question.rawText, base.question.rawText);
    expect(finalReq.spread.spreadId, base.spread.spreadId);
    expect(finalReq.cards.length, base.cards.length);
    expect(finalReq.relationships.length, base.relationships.length);
    expect(finalReq.recurringCards, isNotEmpty);
    expect(finalReq.recurringThemes, isNotEmpty);
    expect(finalReq.memory.included, isTrue);
    final cr = finalReq.recurringCards
        .expand((r) => r.occurrences)
        .where((o) => o.spreadId == 'signature.crossroads');
    expect(cr, isNotEmpty);
    expect(cr.first.positionKey, 'option_a');

    final prompt = NarrativeTarotPromptSerializer.serialize(finalReq);
    final encoded = NarrativeTarotWireContract.payloadFor(prompt).toString();
    expect(encoded.contains('sourceId'), isFalse);
    expect(encoded.contains('ownerId'), isFalse);
    expect(encoded.contains('evidenceId'), isFalse);
    expect(prompt.memory.included, isTrue);

    final blocked = NarrativeTarotClassicalShadow.evaluate(
      session: session,
      readingId: 'read_hist_6e',
      languageCode: 'en',
      history: history,
      privacyBlocked: true,
      now: now,
    );
    expect(blocked.isPass, isTrue);
    expect(blocked.finalNarrativeRequest!.recurringCards, isEmpty);
    expect(blocked.finalNarrativeRequest!.memory.included, isFalse);
  });
}
