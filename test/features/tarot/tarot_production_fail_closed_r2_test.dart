/// R2 — production Tarot interpretation fail-closed / no canned fallback.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/safety/sensitive_topic_gate.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/tarot/components/tarot_error_state.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/interpretation/executors/ai_interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/executors/interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/executors/local_interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_error.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_request.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_stream_event.dart';
import 'package:oracly_new/features/tarot/interpretation/services/interpretation_engine.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:oracly_new/features/tarot/shared/tarot_interpretation_wiring.dart';
import 'package:oracly_new/shared/widgets/oracly_error_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_gem_authority.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  group('A — configured production provider failure', () {
    test('throws InterpretationException — no local synthesis', () async {
      final service = _service(
        executor: _FailingExecutor(),
        allowLocalFallback: false,
      );
      await expectLater(
        service.generateContent(_session()),
        throwsA(
          isA<InterpretationException>().having(
            (e) => e.message,
            'message',
            isNot(contains('HTTP')),
          ),
        ),
      );
    });
  });

  group('B — quality rejection exhaustion', () {
    test('throws when quality fails twice and fallback disabled', () async {
      final service = _service(
        executor: _CertaintyQualityExecutor(),
        allowLocalFallback: false,
      );
      await expectLater(
        service.generateContent(_session()),
        throwsA(isA<InterpretationException>()),
      );
    });
  });

  group('C — development local fallback', () {
    test('local synthesis remains when allowLocalFallback is true', () async {
      final service = _service(
        executor: _FailingExecutor(),
        allowLocalFallback: true,
      );
      final content = await service.generateContent(_session());
      expect(content, isA<AiReadingContent>());
      expect(content.generalMeaning.trim(), isNotEmpty);
      expect(content.isAiInterpretation, isFalse);
    });
  });

  group('D — unconfigured release wiring', () {
    test('does not choose LocalInterpretationExecutor', () {
      const ai = UnconfiguredOraclyAiService(allowsLocalFallback: false);
      expect(ai.isConfigured, isFalse);
      expect(ai.allowsLocalFallback, isFalse);
      final executor = tarotInterpretationExecutorFor(ai);
      expect(executor, isA<AiInterpretationExecutor>());
      expect(executor, isNot(isA<LocalInterpretationExecutor>()));
    });

    test('development unconfigured may use local executor', () {
      const ai = UnconfiguredOraclyAiService(allowsLocalFallback: true);
      final executor = tarotInterpretationExecutorFor(ai);
      expect(executor, isA<LocalInterpretationExecutor>());
    });

    test('configured AI always uses AiInterpretationExecutor', () {
      final executor = tarotInterpretationExecutorFor(_ConfiguredFailingAi());
      expect(executor, isA<AiInterpretationExecutor>());
    });
  });

  group('E — UI error / retry surface', () {
    testWidgets('production failure shows TarotErrorState, not premium body', (
      tester,
    ) async {
      var retried = false;
      // Mirrors ReadingScreen when _contentData stays null after fail-closed.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TarotErrorState(
              message: TarotPolishCopy.interpretFailed,
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      expect(find.byType(TarotErrorState), findsOneWidget);
      expect(find.byType(OraclyErrorState), findsOneWidget);
      expect(find.byType(ReadingPremiumBody), findsNothing);
      expect(find.text(ResilienceCopy.retryAction), findsOneWidget);
      await tester.tap(find.text(ResilienceCopy.retryAction));
      expect(retried, isTrue);
    });
  });

  group('F — no successful persistence / charge from fallback', () {
    test('fail-closed load is free and returns null content', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final wallet = FakeGemAuthority(balance: 50).wallet(storage);
      await wallet.refresh();
      final completion = TarotReadingCompletion(
        charge: TarotReadingCharge(wallet, storage),
      );
      final service = _service(
        executor: _FailingExecutor(),
        allowLocalFallback: false,
      );
      final result = await completion.complete(
        _session(),
        load: () => service.generateContent(_session()),
      );
      expect(result, isNull);
      expect(wallet.balance, 50);
    });

    test('successful retry after fail-closed charges once', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final wallet = FakeGemAuthority(balance: 50).wallet(storage);
      await wallet.refresh();
      final completion = TarotReadingCompletion(
        charge: TarotReadingCharge(wallet, storage),
      );
      final failing = _service(
        executor: _FailingExecutor(),
        allowLocalFallback: false,
      );
      expect(
        await completion.complete(
          _session(),
          load: () => failing.generateContent(_session()),
        ),
        isNull,
      );
      expect(wallet.balance, 50);
      final localOk = _service(
        executor: LocalInterpretationExecutor(),
        allowLocalFallback: true,
      );
      final ok = await completion.complete(
        _session(),
        load: () => localOk.generateContent(_session()),
      );
      expect(ok, isNotNull);
      expect(wallet.balance, 30);
    });
  });

  group('G — sensitive topic safety fallback preserved', () {
    test('crisis intention still returns emergency content', () async {
      const crisis = 'Kendimi öldürmek istiyorum';
      final safety = SensitiveTopicGate.maybeRespond(crisis);
      expect(safety, isNotNull);
      final service = _service(
        executor: _FailingExecutor(),
        allowLocalFallback: false,
      );
      final content = await service.generateContent(
        _session(intention: crisis),
      );
      // Emergency path short-circuits before the failing executor.
      expect(content.dailyAdvice, safety);
      expect(content.generalMeaning.trim(), isNotEmpty);
    });
  });
}

TarotInterpretationService _service({
  required InterpretationExecutor executor,
  required bool allowLocalFallback,
}) {
  return TarotInterpretationService(
    allowLocalFallback: allowLocalFallback,
    engine: InterpretationEngineFactory.create(
      cache: InMemoryInterpretationCache(),
      executor: executor,
    ),
  );
}

ReadingSession _session({String intention = 'Genel rehberlik'}) {
  final reveal = CardRevealSpread.forIndex(0);
  return ReadingSession(
    id: 'r2_session',
    deckId: 'classic',
    spread: TarotSpreadType.threeCard,
    intention: TarotIntention(text: intention),
    shuffleSeed: 7,
    startedAt: DateTime(2026, 9, 22),
    drawnCards: [
      for (var i = 0; i < 3; i++)
        TarotDrawnCard(
          card: reveal.card,
          positionIndex: i,
          isReversed: false,
          positionLabel: 'Şimdi',
        ),
    ],
  );
}

class _FailingExecutor implements InterpretationExecutor {
  @override
  bool get isOnline => true;

  @override
  Future<InterpretationResult> execute(InterpretationRequest request) async {
    throw const InterpretationException(
      type: InterpretationFailureType.retry,
      message: 'Okuma tamamlanamadı. Lütfen tekrar dene.',
    );
  }

  @override
  Stream<InterpretationStreamEvent> executeStream(
    InterpretationRequest request,
  ) => const Stream.empty();
}

/// Structured AI result that passes engine validation but fails quality.
class _CertaintyQualityExecutor implements InterpretationExecutor {
  @override
  bool get isOnline => true;

  static const _bad =
      'Kesin 3 hafta içinde haber alacaksın ve her şey kesin değişecek.';

  @override
  Future<InterpretationResult> execute(InterpretationRequest request) async {
    return InterpretationResult(
      requestId: request.requestId,
      sessionId: request.context.sessionId,
      summary: _bad,
      love: _bad,
      career: _bad,
      money: _bad,
      health: _bad,
      spiritualGuidance: _bad,
      advice: _bad,
      warnings: _bad,
      luckyEnergy: _bad,
      dailyFocus: _bad,
      closingMessage: _bad,
      generatedAt: DateTime.now(),
      source: InterpretationSource.ai,
    );
  }

  @override
  Stream<InterpretationStreamEvent> executeStream(
    InterpretationRequest request,
  ) => const Stream.empty();
}

class _ConfiguredFailingAi implements OraclyAiService {
  @override
  bool get isConfigured => true;
  @override
  bool get visionAvailable => false;
  @override
  bool get allowsLocalFallback => false;

  @override
  Future<AiOutcome<ChatAiReply>> generateTarotReading({
    required List<Map<String, dynamic>> cards,
    required String spreadLabel,
    String? userQuestion,
    String? readingTheme,
    Map<String, dynamic>? journeyHints,
  }) async => AiOutcome.failure(AiFailure.noConfiguration());

  @override
  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async => AiOutcome.failure(AiFailure.noConfiguration());

  @override
  Future<AiOutcome<ChatAiReply>> askOracle({
    required ReadingAiContext context,
    required String userMessage,
    List<String> priorUser = const [],
    List<String> observedThemes = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async => AiOutcome.failure(AiFailure.noConfiguration());

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(
    DreamAiContext context,
  ) async => AiOutcome.failure(AiFailure.noConfiguration());

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
    Map<String, dynamic>? personalization,
  }) async => AiOutcome.failure(AiFailure.noConfiguration());

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  }) async => AiOutcome.failure(AiFailure.noConfiguration());
}
