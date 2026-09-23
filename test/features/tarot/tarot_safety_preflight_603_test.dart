/// Phase 6.0.3 — safety preflight before affordability + quality retry firewall.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/reading_feedback/presentation/widgets/reading_quality_actions.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/interpretation/executors/interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_request.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_stream_event.dart';
import 'package:oracly_new/features/tarot/interpretation/services/interpretation_engine.dart';
import 'package:oracly_new/features/tarot/presentation/screens/reading_screen.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_gem_authority.dart';

AiReadingContent _usable({
  TarotReadingDeliveryKind kind = TarotReadingDeliveryKind.interpretation,
}) {
  return AiReadingContent(
    cardName: 'The Star',
    tagline: 'hope',
    generalMeaning: 'A calm reflection for this table.',
    love: 'l',
    career: 'c',
    money: 'm',
    spiritualGuidance: 's',
    luckyEnergy: 'e',
    dailyAdvice: 'd',
    imageAsset: 'x.png',
    rarityColor: const Color(0xFF000000),
    fullInterpretation: 'A calm reflection for this table.',
    deliveryKind: kind,
  );
}

ReadingSession _drawnSession(
  String id, {
  String intention = 'Genel rehberlik',
  String? interpretation,
}) {
  final reveal = CardRevealSpread.forIndex(0);
  return ReadingSession(
    id: id,
    deckId: 'classic',
    spread: TarotSpreadType.threeCard,
    intention: TarotIntention(text: intention),
    shuffleSeed: 7,
    startedAt: DateTime(2026, 9, 23),
    interpretation: interpretation,
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

  group('affordability matrix', () {
    late LocalStorage storage;
    late GemWalletService wallet;
    late TarotReadingCharge charge;
    late TarotReadingCompletion completion;
    late FakeGemAuthority authority;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorage(await SharedPreferences.getInstance());
      authority = FakeGemAuthority(balance: 0);
      wallet = authority.wallet(storage);
      charge = TarotReadingCharge(wallet, storage);
      completion = TarotReadingCompletion(charge: charge);
      await wallet.refresh();
    });

    test('A — safety / balance 0 returns safety without load', () async {
      var loadCalls = 0;
      final content = await completion.complete(
        _drawnSession(
          'safe-zero',
          intention: 'Intihar etmeyi düşünüyorum',
        ),
        load: () async {
          loadCalls++;
          throw StateError('load must not run for safety');
        },
      );
      expect(content, isNotNull);
      expect(content!.deliveryKind, TarotReadingDeliveryKind.safety);
      expect(loadCalls, 0);
      expect(wallet.balance, 0);
      expect(charge.alreadyCharged('safe-zero'), isFalse);
    });

    test('B — safety / sufficient balance still free, load untouched', () async {
      authority.balance = 50;
      await wallet.refresh();
      var loadCalls = 0;
      final content = await completion.complete(
        _drawnSession(
          'safe-rich',
          intention: 'Intihar etmeyi düşünüyorum',
        ),
        load: () async {
          loadCalls++;
          throw StateError('load must not run for safety');
        },
      );
      expect(content, isNotNull);
      expect(content!.deliveryKind, TarotReadingDeliveryKind.safety);
      expect(loadCalls, 0);
      expect(wallet.balance, 50);
      expect(charge.alreadyCharged('safe-rich'), isFalse);
    });

    test('C — normal / insufficient gems fails before load', () async {
      var loadCalls = 0;
      final content = await completion.complete(
        _drawnSession('normal-poor'),
        load: () async {
          loadCalls++;
          return _usable();
        },
      );
      expect(content, isNull);
      expect(loadCalls, 0);
      expect(wallet.balance, 0);
      expect(charge.alreadyCharged('normal-poor'), isFalse);
    });

    test('D — normal / sufficient gems charges once via load', () async {
      authority.balance = 50;
      await wallet.refresh();
      var loadCalls = 0;
      final content = await completion.complete(
        _drawnSession('normal-ok'),
        load: () async {
          loadCalls++;
          return _usable();
        },
      );
      expect(content, isNotNull);
      expect(content!.deliveryKind, TarotReadingDeliveryKind.interpretation);
      expect(loadCalls, 1);
      expect(wallet.balance, 30);
      expect(charge.alreadyCharged('normal-ok'), isTrue);
    });
  });

  group('quality actions slot', () {
    testWidgets('safety hides ReadingQualityActions', (tester) async {
      final safety = _usable(kind: TarotReadingDeliveryKind.safety);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TarotReadingQualityActionsSlot(
              content: safety,
              sectionMaster: 1,
              retry: () async => false,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ReadingQualityActions), findsNothing);
    });

    testWidgets('normal shows ReadingQualityActions when revealed', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TarotReadingQualityActionsSlot(
              content: _usable(),
              sectionMaster: 1,
              retry: () async => false,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ReadingQualityActions), findsOneWidget);
    });
  });

  group('controller safety reinterpret firewall', () {
    test('safety resolve does not write session interpretation', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final counting = _CountingExecutor();
      final service = TarotInterpretationService(
        allowLocalFallback: false,
        engine: InterpretationEngineFactory.create(
          cache: InMemoryInterpretationCache(),
          executor: counting,
        ),
      );
      final reading = TarotReadingController(
        repository: TarotReadingRepositoryImpl.fromStorage(storage),
        interpretationService: service,
      );
      addTearDown(reading.dispose);

      const prior = 'prior interpretation must remain';
      await reading.updateSession(
        _drawnSession(
          'retry-safe',
          intention: 'Intihar etmeyi düşünüyorum',
          interpretation: prior,
        ),
      );

      final content = await reading.resolveInterpretationContent(
        forceRefresh: true,
      );
      expect(content.isSafetyResponse, isTrue);
      expect(counting.calls, 0);
      expect(reading.session!.interpretation, prior);
    });

    test('null interpretation stays null after safety resolve', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final service = TarotInterpretationService(
        allowLocalFallback: false,
        engine: InterpretationEngineFactory.create(
          cache: InMemoryInterpretationCache(),
          executor: _CountingExecutor(),
        ),
      );
      final reading = TarotReadingController(
        repository: TarotReadingRepositoryImpl.fromStorage(storage),
        interpretationService: service,
      );
      addTearDown(reading.dispose);

      await reading.updateSession(
        _drawnSession(
          'retry-null',
          intention: 'Intihar etmeyi düşünüyorum',
        ),
      );
      expect(reading.session!.interpretation, isNull);

      final content = await reading.resolveInterpretationContent(
        forceRefresh: true,
      );
      expect(content.isSafetyResponse, isTrue);
      expect(reading.session!.interpretation, isNull);
    });
  });
}
