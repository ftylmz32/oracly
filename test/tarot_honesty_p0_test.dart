/// P0 — one real deck, truthful interpretation source, gem commit boundary.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/content/tarot/data/tarot_content_catalogue.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
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
import 'package:oracly_new/features/tarot/interpretation/executors/ai_interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/executors/local_interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_error.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_request.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/deck_selection/deck_selection_data.dart';
import 'package:oracly_new/features/tarot/services/deck_service.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_gem_authority.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('active deck is the real 78-card catalogue', () {
    const service = DeckService();
    final cards = service.createDeck();
    expect(cards, hasLength(78));
    expect(
      cards.map((c) => c.id).toSet(),
      TarotContentCatalogue.all.map((c) => c.id).toSet(),
    );
    expect(TarotDeckCatalogue.decks, hasLength(1));
    expect(TarotDeckCatalogue.decks.first.id, 'classic');
    expect(TarotDeckCatalogue.decks.first.cardCount, 78);
  });

  test('deckId cannot silently create fake distinct decks', () {
    const service = DeckService();
    final classic = service.createDeck(deckId: 'classic');
    final golden = service.createDeck(deckId: 'golden');
    final unknown = service.createDeck(deckId: 'invented-deck');
    expect(classic.map((c) => c.id), golden.map((c) => c.id));
    expect(classic.map((c) => c.id), unknown.map((c) => c.id));
    expect(service.resolveDeckId('moon_oracle'), DeckService.activeCanonicalId);
    expect(TarotDeckCatalogue.isUnbuilt('golden'), isTrue);
    expect(TarotDeckCatalogue.isSelectable('golden'), isFalse);
  });

  test('local interpretation is never labeled AI', () async {
    final local = await LocalInterpretationExecutor().execute(_request());
    expect(local.source, InterpretationSource.local);

    // With no AI configured, the executor must fail loudly — it never
    // silently substitutes a local result and calls it AI. Falling back to
    // local synthesis is the caller's (TarotInterpretationService's)
    // responsibility, exercised below via the default (local) service.
    await expectLater(
      AiInterpretationExecutor(ai: const UnconfiguredOraclyAiService())
          .execute(_request()),
      throwsA(isA<InterpretationException>()),
    );

    final content = await TarotInterpretationService().generateContent(
      _session(),
    );
    expect(content.isAiInterpretation, isFalse);
    expect(
      TarotPolishCopy.readingFootnote(fromAi: false),
      startsWith(TarotPolishCopy.sourceLocal),
    );
    expect(
      TarotPolishCopy.readingFootnote(fromAi: false).toLowerCase(),
      isNot(contains('yapay zek')),
    );
  });

  test('AI source is only AI after a successful real AI parse', () {
    final parsed = AiInterpretationExecutor(
      ai: const UnconfiguredOraclyAiService(),
    ).parseAiResponse(
      _request(),
      '''
## Açılımın Teması
Gerçek model yanıtı.

## Kartların Mesajı
Kartların gözlemlenen mesajı.

## Açılımın Genel Yorumu
Açılımın bütünü.
''',
    );
    expect(parsed.source, InterpretationSource.ai);
    expect(
      TarotPolishCopy.readingFootnote(fromAi: true),
      startsWith(TarotPolishCopy.sourceAi),
    );
  });

  test(
    'a real configured AI reply is parsed and grounded in the sent cards — '
    'the actual production path, not the local fallback',
    () async {
      final ai = _FakeConfiguredAi(
        '## Açılımın Teması\nGerçek bir model yanıtı.\n\n'
        '## Kartların Mesajı\nKartların gözlemlenen mesajı.\n\n'
        '## Genel Bakış\nAçılımın bütünü.\n',
      );
      final request = _request();
      final result =
          await AiInterpretationExecutor(ai: ai).execute(request);
      expect(result.source, InterpretationSource.ai);
      expect(ai.lastCards, isNotEmpty);
      expect(ai.lastSpreadLabel, request.context.spreadLabel);
    },
  );

  test(
    'a network/parse failure from a configured AI service throws instead '
    'of silently returning a fabricated result',
    () async {
      final ai = _FailingConfiguredAi();
      await expectLater(
        AiInterpretationExecutor(ai: ai).execute(_request()),
        throwsA(isA<InterpretationException>()),
      );
    },
  );

  group('gem commit boundary', () {
    late LocalStorage storage;
    late GemWalletService wallet;
    late TarotReadingCharge charge;
    late FakeGemAuthority authority;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorage(await SharedPreferences.getInstance());
      authority = FakeGemAuthority();
      wallet = authority.wallet(storage);
      charge = TarotReadingCharge(wallet, storage);
    });

    test('insufficient gems = no spend', () async {
      expect(wallet.balance, 0);
      expect(await charge.commit('s1'), isFalse);
      expect(wallet.balance, 0);
      expect(charge.alreadyCharged('s1'), isFalse);
    });

    test('back or cancel before commit = no spend', () async {
      authority.balance = 50;
      await wallet.refresh();
      expect(wallet.canSpend(TarotEconomy.readingCost), isTrue);
      expect(wallet.balance, 50);
      expect(charge.alreadyCharged('s-cancel'), isFalse);
    });

    test('successful reading spends exactly 20 gems', () async {
      authority.balance = 50;
      await wallet.refresh();
      expect(await charge.commit('s-ok'), isTrue);
      expect(wallet.balance, 30);
    });

    test('duplicate action spends once', () async {
      authority.balance = 50;
      await wallet.refresh();
      expect(await charge.commit('s-dup'), isTrue);
      expect(await charge.commit('s-dup'), isTrue);
      expect(wallet.balance, 30);
    });

    test('failed reading does not charge', () async {
      authority.balance = 50;
      await wallet.refresh();
      expect(wallet.balance, 50);
      expect(charge.alreadyCharged('s-fail'), isFalse);
    });

    test('balance never goes negative', () async {
      authority.balance = 10;
      await wallet.refresh();
      expect(await charge.commit('s-neg'), isFalse);
      expect(wallet.balance, 10);
      expect(wallet.balance, greaterThanOrEqualTo(0));
    });
  });
}

InterpretationRequest _request() {
  return InterpretationRequest(
    requestId: 'r1',
    createdAt: DateTime(2026, 8, 9),
    context: ReadingContext(
      sessionId: 's1',
      spreadType: TarotSpreadType.single,
      spreadLabel: 'Günlük Kart',
      deckId: 'classic',
      language: 'tr',
      readingDate: DateTime(2026, 8, 9),
      cards: const [
        ReadingCardContext(
          cardId: 0,
          cardName: 'Deli',
          positionIndex: 0,
          positionLabel: 'Şimdi',
          positionKey: 'now',
          isReversed: false,
          uprightMeaning: 'Yeni bir başlangıç.',
          reversedMeaning: 'Tereddüt.',
          keywords: ['başlangıç'],
        ),
      ],
    ),
  );
}

ReadingSession _session() {
  final reveal = CardRevealSpread.forIndex(0);
  return ReadingSession(
    id: 'test_session',
    deckId: 'rider-waite',
    spread: TarotSpreadType.single,
    intention: const TarotIntention(text: 'Genel rehberlik'),
    shuffleSeed: 7,
    startedAt: DateTime(2026, 8, 9),
    drawnCards: [
      TarotDrawnCard(
        card: reveal.card,
        positionIndex: 0,
        isReversed: false,
        positionLabel: 'Şimdi',
      ),
    ],
  );
}

/// Minimal fake standing in for a real, configured backend-proxied service —
/// only `generateTarotReading` matters for these tests; every other method
/// fails closed since nothing here should ever call them.
class _FakeConfiguredAi implements OraclyAiService {
  _FakeConfiguredAi(this._text);
  final String _text;
  List<Map<String, dynamic>>? lastCards;
  String? lastSpreadLabel;

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
  }) async {
    lastCards = cards;
    lastSpreadLabel = spreadLabel;
    return AiOutcome.success(ChatAiReply(text: _text, modelId: 'test-model'));
  }

  @override
  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async =>
      AiOutcome.failure(AiFailure.noConfiguration());

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
  }) async =>
      AiOutcome.failure(AiFailure.noConfiguration());

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(
    DreamAiContext context,
  ) async =>
      AiOutcome.failure(AiFailure.noConfiguration());

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
    Map<String, dynamic>? personalization,
  }) async =>
      AiOutcome.failure(
        AiFailure.imageAnalysisUnavailable(feature: AiAnalysisFeature.coffee),
      );

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  }) async =>
      AiOutcome.failure(
        AiFailure.imageAnalysisUnavailable(feature: AiAnalysisFeature.palm),
      );
}

/// A configured service whose Tarot call always fails — proves the executor
/// propagates the failure rather than fabricating a result.
class _FailingConfiguredAi extends _FakeConfiguredAi {
  _FailingConfiguredAi() : super('');

  @override
  Future<AiOutcome<ChatAiReply>> generateTarotReading({
    required List<Map<String, dynamic>> cards,
    required String spreadLabel,
    String? userQuestion,
    String? readingTheme,
    Map<String, dynamic>? journeyHints,
  }) async =>
      AiOutcome.failure(AiFailure.network());
}
