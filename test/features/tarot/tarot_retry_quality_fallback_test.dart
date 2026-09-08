import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/cache/interpretation_cache.dart';
import 'package:oracly_new/features/tarot/interpretation/executors/local_interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_error.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_request.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/interpretation/services/interpretation_engine.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';

void main() {
  test('low-quality force-refresh retry is never shown to the user', () async {
    final engine = _FailThenLowQualityEngine();
    final service = TarotInterpretationService(engine: engine);

    final content = await service.generateContent(_session());

    expect(engine.forceRefreshCalls, [false, true]);
    expect(content.fullInterpretation, isNot(contains(_retryMarker)));
    expect(content.generalMeaning, isNot(contains(_retryMarker)));
    expect(
      '${content.generalMeaning} ${content.dailyAdvice} ${content.fullInterpretation}',
      contains('karar'),
    );
  });
}

const _retryMarker = 'LOW_QUALITY_RETRY_SHOULD_NEVER_RENDER';
const _repetitiveRetry =
    '$_retryMarker karar yol denge enerji bugün yarın seçenek hareket duraklama odak';

class _FailThenLowQualityEngine extends InterpretationEngine {
  _FailThenLowQualityEngine()
      : super(
          executor: LocalInterpretationExecutor(),
          cache: _NoopCache(),
        );

  final List<bool> forceRefreshCalls = <bool>[];

  @override
  Future<InterpretationResult> interpret({
    required ReadingContext context,
    bool forceRefresh = false,
    InterpretationMode mode = InterpretationMode.standard,
  }) async {
    forceRefreshCalls.add(forceRefresh);
    if (!forceRefresh) {
      throw const InterpretationException(
        type: InterpretationFailureType.invalidResponse,
        message: 'primary failed',
      );
    }
    return InterpretationResult(
      requestId: 'retry',
      sessionId: context.sessionId,
      summary: _repetitiveRetry,
      love: '',
      career: _repetitiveRetry,
      money: '',
      health: '',
      spiritualGuidance: '',
      advice: _repetitiveRetry,
      warnings: '',
      luckyEnergy: '',
      dailyFocus: '',
      closingMessage: '',
      generatedAt: DateTime(2026, 9, 8),
      source: InterpretationSource.ai,
    );
  }
}

class _NoopCache implements InterpretationCache {
  @override
  Future<InterpretationResult?> get(String cacheKey) async => null;

  @override
  Future<void> set(String cacheKey, InterpretationResult result) async {}

  @override
  Future<void> invalidate(String cacheKey) async {}

  @override
  Future<void> invalidateSession(String sessionId) async {}
}

ReadingSession _session() => ReadingSession(
      id: 'retry-quality-session',
      deckId: 'classic',
      spread: TarotSpreadType.single,
      intention: const TarotIntention(
        text: 'İşimle ilgili hangi kararı daha net görmeliyim?',
        topic: 'career',
      ),
      shuffleSeed: 7,
      startedAt: DateTime(2026, 9, 8),
      drawnCards: const [
        TarotDrawnCard(
          card: TarotCard(
            id: 2,
            name: 'Two of Swords',
            image: '',
            arcana: TarotArcana.minor,
            suit: TarotSuit.swords,
            rank: TarotRank.two,
            number: 2,
            summary: 'Karar ve denge.',
            meaning: 'Karar verirken iki tarafı da görme ihtiyacı.',
            reversedMeaning: 'Kararsızlığın çözülmeye başlaması.',
            keywords: ['karar', 'denge'],
          ),
          positionIndex: 0,
          isReversed: false,
          positionLabel: 'Şimdi',
          positionKey: 'present',
        ),
      ],
    );
