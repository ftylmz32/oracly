import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/models/tarot_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/insights/models/journey_personalization_hints.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/executors/ai_interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_error.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_request.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';

class _SuccessAi extends UnconfiguredOraclyAiService {
  _SuccessAi();

  TarotAiRequestContext? captured;

  @override
  bool get isConfigured => true;

  @override
  Future<AiOutcome<TarotAiAnalysis>> analyzeTarot(
    TarotAiRequestContext context,
  ) async {
    captured = context;
    return AiOutcome.success(const TarotAiAnalysis(
      summary: 'Kartlar karar ile hareket arasındaki gerilimi öne çıkarıyor.',
      love: '',
      career: 'İş tarafında seçenekleri ayırmak daha görünür duruyor.',
      money: '',
      health: 'Şimdi konumundaki kart karar baskısını sembolik olarak taşıyor.',
      spiritualGuidance: '',
      advice: 'İki seçeneğin bedelini ayrı ayrı yaz.',
      warnings: 'Aceleyi karar sanıyor olabilir misin?',
      luckyEnergy: 'Açılımın bütünü kararın ardından hareketi anlatıyor.',
      dailyFocus: 'Bugün tek bir ölçüt belirle.',
      closingMessage: 'İstersen iki seçeneği birlikte açabiliriz.',
    ));
  }
}

class _FailAi extends UnconfiguredOraclyAiService {
  const _FailAi();

  @override
  bool get isConfigured => true;

  @override
  Future<AiOutcome<TarotAiAnalysis>> analyzeTarot(
    TarotAiRequestContext context,
  ) async => AiOutcome.failure(AiFailure.invalidResponse());
}

ReadingContext _context() => ReadingContext(
      sessionId: 's1',
      spreadType: TarotSpreadType.threeCard,
      spreadLabel: 'Üç Kart',
      deckId: 'classic',
      language: 'tr',
      readingDate: DateTime(2026, 9, 5),
      userQuestion: 'İşimle ilgili neyi görmüyorum?',
      readingTheme: 'career',
      cards: const [
        ReadingCardContext(
          cardId: 2,
          cardName: 'Two of Swords',
          positionIndex: 0,
          positionLabel: 'Şimdi',
          positionKey: 'present',
          isReversed: false,
          uprightMeaning: 'Karar ve denge.',
          reversedMeaning: 'Kararsızlığın çözülmesi.',
          keywords: ['karar', 'denge'],
        ),
      ],
      journeyHints: const JourneyPersonalizationHints(
        recurringThemeLabels: ['karar'],
        recentCardNames: ['Eight of Wands'],
        priorReadingCount: 3,
      ),
    );

void main() {
  test('executor sends real cards and separate continuity then marks AI source', () async {
    final ai = _SuccessAi();
    final executor = AiInterpretationExecutor(ai: ai);
    final result = await executor.execute(InterpretationRequest(
      context: _context(),
      requestId: 'r1',
      createdAt: DateTime(2026, 9, 5),
    ));

    final sent = ai.captured!;
    expect(sent.cards, hasLength(1));
    expect(sent.cards.single.cardName, 'Two of Swords');
    expect(sent.cards.single.meaning, 'Karar ve denge.');
    expect(sent.continuity.recurringThemes, ['karar']);
    expect(sent.continuity.recentCardNames, ['Eight of Wands']);
    expect(result.source, InterpretationSource.ai);
    expect(result.summary, contains('karar'));
  });

  test('provider failure is thrown instead of being mislabeled as AI', () async {
    final executor = AiInterpretationExecutor(ai: const _FailAi());
    expect(
      () => executor.execute(InterpretationRequest(
        context: _context(),
        requestId: 'r2',
        createdAt: DateTime(2026, 9, 5),
      )),
      throwsA(isA<InterpretationException>()),
    );
  });
}
