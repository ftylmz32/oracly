/// Phase 6.0.2 — safety purity, recovery authorization, delivery-kind copy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/insight_copy/widgets/insight_copy_link.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading_version/adapters/tarot_version_content.dart';
import 'package:oracly_new/core/safety/sensitive_topic_gate.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/interpretation/executors/interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_request.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_stream_event.dart';
import 'package:oracly_new/features/tarot/interpretation/services/interpretation_engine.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_detail_layers.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_cards_block.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_sections.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_story_strip.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_gem_authority.dart';

const _sentinel = 'FORBIDDEN_CARD_FORTUNE_TEXT_6012';

AiReadingContent _usable({
  TarotReadingDeliveryKind kind = TarotReadingDeliveryKind.interpretation,
  String prose = 'A calm reflection for this table.',
}) {
  return AiReadingContent(
    cardName: 'The Star',
    tagline: 'hope',
    generalMeaning: prose,
    love: 'love-body',
    career: 'career-body',
    money: 'money-body',
    spiritualGuidance: 'spirit-body',
    luckyEnergy: 'lucky-body',
    dailyAdvice: 'advice-body',
    imageAsset: 'x.png',
    rarityColor: const Color(0xFF000000),
    fullInterpretation: prose,
    deliveryKind: kind,
  );
}

TarotCard _sentinelCard() => const TarotCard(
      id: 99901,
      name: 'Sentinel Card',
      image: '',
      arcana: TarotArcana.major,
      suit: TarotSuit.none,
      number: 0,
      summary: 'summary',
      meaning: _sentinel,
      reversedMeaning: _sentinel,
      keywords: ['test'],
    );

ReadingSession _drawnSession(
  String id, {
  String intention = 'Genel rehberlik',
  TarotCard? card,
}) {
  final drawnCard = card ?? _sentinelCard();
  return ReadingSession(
    id: id,
    deckId: 'classic',
    spread: TarotSpreadType.threeCard,
    intention: TarotIntention(text: intention),
    shuffleSeed: 7,
    startedAt: DateTime(2026, 9, 23),
    drawnCards: [
      TarotDrawnCard(
        card: drawnCard,
        positionIndex: 0,
        isReversed: false,
        positionLabel: 'Şimdi',
      ),
    ],
  );
}

class _CountingExecutor implements InterpretationExecutor {
  int calls = 0;

  @override
  bool get isOnline => true;

  @override
  Future<InterpretationResult> execute(InterpretationRequest request) async {
    calls++;
    throw StateError('executor must not run for safety');
  }

  @override
  Stream<InterpretationStreamEvent> executeStream(
    InterpretationRequest request,
  ) async* {
    calls++;
    throw StateError('executor must not run for safety');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  group('safety content purity', () {
    test('safety contains zero card-derived interpretive prose', () async {
      final counting = _CountingExecutor();
      final service = TarotInterpretationService(
        allowLocalFallback: false,
        engine: InterpretationEngineFactory.create(
          cache: InMemoryInterpretationCache(),
          executor: counting,
        ),
      );
      const crisis = 'Intihar etmeyi düşünüyorum';
      final reason = SensitiveTopicGate.maybeRespond(crisis);
      expect(reason, isNotNull);

      final content = await service.generateContent(
        _drawnSession('pure-safe', intention: crisis),
      );

      expect(content.deliveryKind, TarotReadingDeliveryKind.safety);
      expect(content.generalMeaning, reason);
      expect(content.fullInterpretation, reason);
      expect(content.generalMeaning, isNot(contains(_sentinel)));
      expect(content.fullInterpretation, isNot(contains(_sentinel)));
      expect(content.love, isEmpty);
      expect(content.career, isEmpty);
      expect(content.money, isEmpty);
      expect(content.spiritualGuidance, isEmpty);
      expect(content.luckyEnergy, isEmpty);
      expect(content.dailyAdvice, isEmpty);
      expect(content.cardReadings, isEmpty);
      expect(content.drawnCards, isEmpty);
      expect(counting.calls, 0);
    });
  });

  group('ReadingPremiumBody safety branch', () {
    testWidgets('safety renders reason without Tarot story stack', (
      tester,
    ) async {
      const reason = 'SAFETY_REASON_VISIBLE_602';
      final safety = AiReadingContent(
        cardName: 'Üç Kart',
        tagline: '',
        generalMeaning: reason,
        love: _sentinel,
        career: _sentinel,
        money: _sentinel,
        spiritualGuidance: _sentinel,
        luckyEnergy: _sentinel,
        dailyAdvice: '',
        imageAsset: '',
        rarityColor: const Color(0x00000000),
        fullInterpretation: reason,
        deliveryKind: TarotReadingDeliveryKind.safety,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingPremiumBody(
              content: safety,
              sectionMaster: 1,
              panelOpacity: 1,
              ambientPhase: 0,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(reason), findsOneWidget);
      expect(find.textContaining(_sentinel), findsNothing);
      expect(find.byType(ReadingStoryStrip), findsNothing);
      expect(find.byType(ReadingPremiumSections), findsNothing);
      expect(find.byType(ReadingPremiumCardsBlock), findsNothing);
      expect(find.byType(ReadingDetailLayers), findsNothing);
      expect(find.byType(InsightCopyLink), findsNothing);
    });

    testWidgets('normal interpretation still renders story body', (
      tester,
    ) async {
      final normal = _usable(prose: 'NORMAL_STORY_PROSE_602');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReadingPremiumBody(
                content: normal,
                sectionMaster: 1,
                panelOpacity: 1,
                ambientPhase: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ReadingStoryStrip), findsOneWidget);
      expect(find.byType(ReadingPremiumSections), findsOneWidget);
      expect(find.byType(InsightCopyLink), findsOneWidget);
      expect(find.textContaining('love-body'), findsWidgets);
    });
  });

  group('recovery authorization', () {
    late LocalStorage storage;
    late GemWalletService wallet;
    late TarotReadingCharge charge;
    late TarotReadingCompletion completion;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorage(await SharedPreferences.getInstance());
      final authority = FakeGemAuthority(balance: 50);
      wallet = authority.wallet(storage);
      charge = TarotReadingCharge(wallet, storage);
      completion = TarotReadingCompletion(charge: charge);
      await wallet.refresh();
    });

    test('unauthorized recovery fails closed', () async {
      final content = await completion.complete(
        _drawnSession('unauth-recover'),
        load: () async => _usable(kind: TarotReadingDeliveryKind.recovery),
      );
      expect(content, isNull);
      expect(wallet.balance, 50);
      expect(charge.alreadyCharged('unauth-recover'), isFalse);
    });

    test('authorized recovery returns without second charge', () async {
      final session = _drawnSession('auth-recover');
      expect(
        await completion.complete(session, load: () async => _usable()),
        isNotNull,
      );
      expect(wallet.balance, 30);

      final recovery = await completion.complete(
        session,
        load: () async => _usable(kind: TarotReadingDeliveryKind.recovery),
      );
      expect(recovery, isNotNull);
      expect(recovery!.deliveryKind, TarotReadingDeliveryKind.recovery);
      expect(wallet.balance, 30);
      expect(charge.alreadyCharged('auth-recover'), isTrue);
    });
  });

  group('delivery kind copy preservation', () {
    test('tarotContentWithSummary keeps recovery and safety kinds', () {
      final recovery = tarotContentWithSummary(
        _usable(kind: TarotReadingDeliveryKind.recovery),
        'versioned summary',
      );
      expect(recovery.deliveryKind, TarotReadingDeliveryKind.recovery);
      expect(recovery.fullInterpretation, 'versioned summary');

      final safety = tarotContentWithSummary(
        _usable(kind: TarotReadingDeliveryKind.safety, prose: 'safe'),
        'should stay safety',
      );
      expect(safety.deliveryKind, TarotReadingDeliveryKind.safety);
    });
  });
}
