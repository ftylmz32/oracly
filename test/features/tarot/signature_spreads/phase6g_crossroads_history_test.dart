/// Phase 6G — Crossroads history enrichment via Signature Evidence path.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_history_spread_normalizer.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_evaluator.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_input.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_status.dart';

import '../narrative_history/tarot_history_test_support.dart';

final _ritualByCanon = <String, int>{
  for (var i = 0; i < 78; i++) OraclyTarotBridge.byRitualId(i)!.id: i,
};

void main() {
  final now = DateTime.utc(2026, 9, 25, 12);
  final ids = OraclyTarotDeck.expectedIds.take(5).toList();

  List<SignatureSpreadShadowCard> cards() => [
        for (var i = 0; i < 5; i++)
          SignatureSpreadShadowCard(
            ritualCardId: _ritualByCanon[ids[i]]!,
            isReversed: false,
            positionIndex: i,
          ),
      ];

  test('11 history normalize remains signature.crossroads', () {
    final n = SignatureHistorySpreadNormalizer.fromSpread(
      TarotSpreadType.crossroads,
    );
    expect(n, isNotNull);
    expect(n!.spreadId, 'signature.crossroads');
    expect(n.spreadId, isNot('classical.fiveCard'));
  });

  test('12–14 owner isolation + privacyBlocked on Signature enrichment', () {
    final hist = TarotHistoricalSnapshot(
      tarotReadings: [
        histReading(
          readingId: 'h1',
          at: now.subtract(const Duration(days: 2)),
          spreadId: 'signature.crossroads',
          cardId: ids[0],
          positionKey: 'option_a',
          topicId: null,
          questionKind: QuestionKind.decision,
          intentionSummary: null,
          ownerId: 'owner-a',
        ),
      ],
    );

    final otherOwner = SignatureSpreadShadowEvaluator.evaluate(
      input: SignatureSpreadShadowInput(
        sessionId: 's',
        readingId: 'r',
        languageCode: 'en',
        spreadType: TarotSpreadType.crossroads,
        questionRaw: 'Should I accept this offer?',
        cards: cards(),
      ),
      history: hist,
      currentOwnerId: 'owner-b',
      privacyBlocked: false,
      now: now,
    );
    expect(otherOwner.ok, isTrue);
    expect(
      otherOwner.phase3EvidenceStatus,
      SignaturePhase3EvidenceStatus.builtSignature,
    );
    expect(
      otherOwner.phase4HistoryStatus,
      SignaturePhase4HistoryStatus.enrichedSignature,
    );
    expect(otherOwner.enrichedRequest!.spread.spreadId, 'signature.crossroads');
    expect(otherOwner.enrichedRequest!.recurringCards, isEmpty);

    final privacy = SignatureSpreadShadowEvaluator.evaluate(
      input: SignatureSpreadShadowInput(
        sessionId: 's',
        readingId: 'r',
        languageCode: 'en',
        spreadType: TarotSpreadType.crossroads,
        questionRaw: 'Should I accept this offer?',
        cards: cards(),
      ),
      history: hist,
      currentOwnerId: 'owner-a',
      privacyBlocked: true,
      now: now,
    );
    expect(
      privacy.phase4HistoryStatus,
      SignaturePhase4HistoryStatus.privacyBlocked,
    );
    expect(privacy.enrichedRequest!.recurringCards, isEmpty);
    expect(privacy.enrichedRequest!.memory.included, isFalse);
  });
}
