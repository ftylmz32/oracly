/// Phase 6.0.1 — safety delivery is non-billable and non-journal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
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
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_gem_authority.dart';

/// Mirrors ReadingScreen journal / footer gates for safety delivery.
bool readingScreenShouldAutoJournal(AiReadingContent content) =>
    content.isJournalEligible;

bool readingScreenShouldPersistToJournalBody(AiReadingContent content) =>
    content.isJournalEligible;

bool readingScreenSaveEnabled(AiReadingContent content, {required bool gateDone}) =>
    content.isJournalEligible && !gateDone;

bool readingScreenReflectionEnabled(
  AiReadingContent content, {
  required bool gateDone,
}) =>
    content.isJournalEligible && gateDone;

bool readingScreenAskOracleEnabled(AiReadingContent content) =>
    !content.isSafetyResponse;

bool readingScreenShareEnabled(AiReadingContent content) =>
    !content.isSafetyResponse;

bool readingScreenFavoriteEnabled(AiReadingContent content) =>
    content.isJournalEligible;

AiReadingContent _usable({
  TarotReadingDeliveryKind kind = TarotReadingDeliveryKind.interpretation,
  String prose = 'A calm reflection for this table.',
}) {
  return AiReadingContent(
    cardName: 'The Star',
    tagline: 'hope',
    generalMeaning: prose,
    love: 'l',
    career: 'c',
    money: 'm',
    spiritualGuidance: 's',
    luckyEnergy: 'e',
    dailyAdvice: 'd',
    imageAsset: 'x.png',
    rarityColor: const Color(0xFF000000),
    fullInterpretation: prose,
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

  group('delivery kind semantics', () {
    test('safety is free and non-journal', () {
      final c = _usable(kind: TarotReadingDeliveryKind.safety);
      expect(c.isSafetyResponse, isTrue);
      expect(c.isChargeEligible, isFalse);
      expect(c.isJournalEligible, isFalse);
    });

    test('interpretation is charge + journal eligible', () {
      final c = _usable();
      expect(c.deliveryKind, TarotReadingDeliveryKind.interpretation);
      expect(c.isChargeEligible, isTrue);
      expect(c.isJournalEligible, isTrue);
    });

    test('recovery is journal-eligible but not a new charge', () {
      final c = _usable(kind: TarotReadingDeliveryKind.recovery);
      expect(c.isChargeEligible, isFalse);
      expect(c.isJournalEligible, isTrue);
    });
  });

  group('service sensitive gate', () {
    test('safety response never touches executor', () async {
      final counting = _CountingExecutor();
      final service = TarotInterpretationService(
        allowLocalFallback: false,
        engine: InterpretationEngineFactory.create(
          cache: InMemoryInterpretationCache(),
          executor: counting,
        ),
      );
      final content = await service.generateContent(
        _drawnSession(
          'safe',
          intention: 'Intihar etmeyi düşünüyorum',
        ),
      );
      expect(content.deliveryKind, TarotReadingDeliveryKind.safety);
      expect(content.isSafetyResponse, isTrue);
      expect(content.generalMeaning.trim(), isNotEmpty);
      expect(counting.calls, 0);
    });
  });

  group('completion billing', () {
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

    test('safety content returns without charging', () async {
      final content = await completion.complete(
        _drawnSession('safety-bill'),
        load: () async => _usable(kind: TarotReadingDeliveryKind.safety),
      );
      expect(content, isNotNull);
      expect(content!.deliveryKind, TarotReadingDeliveryKind.safety);
      expect(wallet.balance, 50);
      expect(charge.alreadyCharged('safety-bill'), isFalse);
    });

    test('interpretation still charges exactly once', () async {
      final first = await completion.complete(
        _drawnSession('normal-bill'),
        load: () async => _usable(),
      );
      expect(first, isNotNull);
      expect(wallet.balance, 30);
      expect(charge.alreadyCharged('normal-bill'), isTrue);

      final second = await completion.complete(
        _drawnSession('normal-bill'),
        load: () async => _usable(),
      );
      expect(second, isNotNull);
      expect(wallet.balance, 30);
    });

    test('recovery after settle does not double-charge', () async {
      final session = _drawnSession('recover');
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
      expect(charge.alreadyCharged('recover'), isTrue);
    });

    test('already-charged provider failure is recovery', () async {
      final session = _drawnSession('recover-throw');
      expect(
        await completion.complete(session, load: () async => _usable()),
        isNotNull,
      );
      final fallback = await completion.complete(
        session,
        load: () async => throw Exception('provider'),
      );
      expect(fallback, isNotNull);
      expect(fallback!.deliveryKind, TarotReadingDeliveryKind.recovery);
      expect(wallet.balance, 30);
    });
  });

  group('controller safety persistence', () {
    test('does not write safety prose into session interpretation', () async {
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
      final session = _drawnSession(
        'ctrl-safe',
        intention: 'Intihar etmeyi düşünüyorum',
        interpretation: prior,
      );
      await reading.updateSession(session);

      final content = await reading.resolveInterpretationContent();
      expect(content.deliveryKind, TarotReadingDeliveryKind.safety);
      expect(content.isSafetyResponse, isTrue);
      expect(counting.calls, 0);
      expect(reading.session!.interpretation, prior);
      expect(
        reading.session!.interpretation,
        isNot(content.fullInterpretation),
      );
      expect(reading.session!.flowStep, ReadingFlowStep.reading);
    });
  });

  group('reading screen safety firewalls', () {
    test('safety blocks auto-journal and manual actions', () {
      final safety = _usable(kind: TarotReadingDeliveryKind.safety);
      expect(readingScreenShouldAutoJournal(safety), isFalse);
      expect(readingScreenShouldPersistToJournalBody(safety), isFalse);
      expect(readingScreenSaveEnabled(safety, gateDone: false), isFalse);
      expect(readingScreenReflectionEnabled(safety, gateDone: true), isFalse);
      expect(readingScreenAskOracleEnabled(safety), isFalse);
      expect(readingScreenShareEnabled(safety), isFalse);
      expect(readingScreenFavoriteEnabled(safety), isFalse);
    });

    test('normal interpretation keeps journal and actions', () {
      final normal = _usable();
      expect(readingScreenShouldAutoJournal(normal), isTrue);
      expect(readingScreenShouldPersistToJournalBody(normal), isTrue);
      expect(readingScreenSaveEnabled(normal, gateDone: false), isTrue);
      expect(readingScreenReflectionEnabled(normal, gateDone: true), isTrue);
      expect(readingScreenAskOracleEnabled(normal), isTrue);
      expect(readingScreenShareEnabled(normal), isTrue);
      expect(readingScreenFavoriteEnabled(normal), isTrue);
    });

    test('recovery remains journal-eligible with actions', () {
      final recovery = _usable(kind: TarotReadingDeliveryKind.recovery);
      expect(readingScreenShouldAutoJournal(recovery), isTrue);
      expect(readingScreenFavoriteEnabled(recovery), isTrue);
      expect(readingScreenAskOracleEnabled(recovery), isTrue);
    });
  });
}
