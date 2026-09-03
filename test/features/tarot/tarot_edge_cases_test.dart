/// Tarot edge-case hardening — charge, restore, questions, provider failure.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/datasources/tarot_local_datasource.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_session_recovery.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_error.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/reading/reading_question.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  group('questions', () {
    test('no question stays a valid general reading', () {
      expect(ReadingQuestion.real(''), isNull);
      expect(ReadingQuestion.real('   '), isNull);
      final result = ReflectiveIntelligence.synthesize(
        context: _ctx(question: ''),
        requestId: 'empty',
      );
      expect(result.summary.trim(), isNotEmpty);
    });

    test('very short question does not crash', () {
      expect(ReadingQuestion.real('?'), '?');
      expect(
        ReflectiveIntelligence.synthesize(
          context: _ctx(question: '?'),
          requestId: 'short',
        ).summary,
        contains('?'),
      );
    });

    test('very long question is clipped', () {
      final long = 'a' * 800;
      final clipped = ReadingQuestion.sanitize(long);
      expect(clipped.length, ReadingQuestion.maxLength);
      expect(
        ReadingContext.fromSession(_session(question: long)).userQuestion?.length,
        ReadingQuestion.maxLength,
      );
    });

    test('special characters are stripped of control codes', () {
      final cleaned = ReadingQuestion.sanitize('\u0000hello\u0007 <tag> &');
      expect(cleaned, isNot(contains('\u0000')));
      expect(cleaned, contains('hello'));
      expect(cleaned, contains('&'));
    });
  });

  group('restore', () {
    test('corrupt active session is discarded, not crashed', () {
      expect(TarotSessionRecovery.decode('{not-json'), isNull);
      expect(TarotSessionRecovery.decode('[]'), isNull);
    });

    test('reveal or reading with no cards is not a fake result', () {
      final repaired = TarotSessionRecovery.prepare(
        _session(cards: 0, step: ReadingFlowStep.reveal),
        activeOnly: true,
      );
      expect(repaired, isNotNull);
      expect(repaired!.flowStep, ReadingFlowStep.cardSelection);
      expect(repaired.drawnCards, isEmpty);
    });

    test('extra drawn cards are clipped', () {
      final base = _session(cards: 3);
      final extra = base.copyWith(
        drawnCards: [...base.drawnCards, ...base.drawnCards],
      );
      final repaired = TarotSessionRecovery.prepare(extra, activeOnly: true);
      expect(repaired!.drawnCards, hasLength(3));
    });

    test('completed leftover is not restored as active', () {
      final done = _session().copyWith(
        status: ReadingSessionStatus.completed,
        flowStep: ReadingFlowStep.completed,
      );
      expect(TarotSessionRecovery.prepare(done, activeOnly: true), isNull);
    });
  });

  group('completion', () {
    late LocalStorage storage;
    late GemWalletService wallet;
    late TarotReadingCompletion completion;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorage(await SharedPreferences.getInstance());
      wallet = GemWalletService(GemWalletStore(storage));
      completion = TarotReadingCompletion(
        charge: TarotReadingCharge(wallet, storage),
      );
      await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
    });

    test('provider failure is free and offers a clean retry', () async {
      expect(
        await completion.complete(
          _session(),
          load: () async => throw Exception('network'),
        ),
        isNull,
      );
      expect(wallet.balance, 50);
      expect(await completion.complete(_session()), isNotNull);
      expect(wallet.balance, 30);
    });

    test('empty provider response is not billed', () async {
      expect(
        await completion.complete(
          _session(),
          load: () async => _emptyContent(),
        ),
        isNull,
      );
      expect(wallet.balance, 50);
    });

    test('timeout is free and does not hang', () async {
      expect(
        await completion.complete(
          _session(),
          timeout: const Duration(milliseconds: 20),
          load: () => Future.delayed(
            const Duration(seconds: 5),
            _emptyContent,
          ),
        ),
        isNull,
      );
      expect(wallet.balance, 50);
    });

    test('insufficient gems do not spend or invent a reading', () async {
      SharedPreferences.setMockInitialValues({});
      final isolated = LocalStorage(await SharedPreferences.getInstance());
      final poor = GemWalletService(GemWalletStore(isolated));
      final blocked = TarotReadingCompletion(
        charge: TarotReadingCharge(poor, isolated),
      );
      expect(poor.balance, 0);
      expect(await blocked.complete(_session()), isNull);
      expect(poor.balance, 0);
    });

    test('already charged provider failure uses real drawn cards', () async {
      final session = _session();
      expect(await completion.complete(session), isNotNull);
      expect(wallet.balance, 30);
      final fallback = await completion.complete(
        session,
        load: () async => throw Exception('provider'),
      );
      expect(fallback, isNotNull);
      expect(fallback!.cardName, isNotEmpty);
      expect(fallback.imageAsset, isNotEmpty);
      expect(wallet.balance, 30);
    });

    test('double complete spends once', () async {
      final session = _session();
      final results = await Future.wait([
        completion.complete(session),
        completion.complete(session),
      ]);
      expect(results.where((c) => c != null), isNotEmpty);
      expect(wallet.history.where((t) => t.amount < 0), hasLength(1));
      expect(wallet.balance, 30);
    });

    test('empty draw is not a fake card result', () async {
      expect(await completion.complete(_session(cards: 0)), isNull);
      expect(wallet.balance, 50);
      await expectLater(
        TarotInterpretationService().generateContent(_session(cards: 0)),
        throwsA(isA<InterpretationException>()),
      );
    });
  });

  group('ritual guards', () {
    late TarotReadingController reading;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      reading = TarotReadingController(
        repository: TarotReadingRepositoryImpl.fromStorage(
          LocalStorage(await SharedPreferences.getInstance()),
        ),
      );
    });

    tearDown(() => reading.dispose());

    test('shuffle does not skip to selection until finished', () async {
      await reading.beginSession(
        spread: TarotSpreadType.threeCard,
        deckId: 'classic',
      );
      await reading.advanceToShuffle();
      await reading.performShuffle();
      expect(reading.session!.flowStep, ReadingFlowStep.shuffle);
      await reading.finishShuffle();
      expect(reading.session!.flowStep, ReadingFlowStep.cardSelection);
    });

    test('double draw cannot invent a second card', () async {
      await reading.beginSession(
        spread: TarotSpreadType.threeCard,
        deckId: 'classic',
      );
      await reading.advanceToShuffle();
      await reading.performShuffle();
      await reading.finishShuffle();
      final results = await Future.wait<Object>([
        reading.drawCard().then<Object>((c) => c).catchError((e) => e),
        reading.drawCard().then<Object>((c) => c).catchError((e) => e),
      ]);
      expect(results.whereType<TarotDrawnCard>(), hasLength(1));
      expect(reading.session!.drawnCards, hasLength(1));
    });

    test('restart of unfinished reading does not invent cards', () async {
      await reading.beginSession(
        spread: TarotSpreadType.threeCard,
        deckId: 'classic',
      );
      await reading.advanceToShuffle();
      await reading.performShuffle();
      await reading.finishShuffle();
      await reading.drawCard();
      await reading.flush();

      final restored = TarotReadingController(
        repository: TarotReadingRepositoryImpl.fromStorage(
          LocalStorage(await SharedPreferences.getInstance()),
        ),
      );
      await restored.restoreActiveSession();
      expect(restored.session!.drawnCards, hasLength(1));
      expect(restored.session!.flowStep, ReadingFlowStep.reveal);
      expect(restored.session!.drawnCards.first.card.name, isNotEmpty);
      restored.dispose();
    });
  });

  test('corrupt storage history does not crash', () async {
    SharedPreferences.setMockInitialValues({
      'or_tarot_active_session': '{broken',
      'or_tarot_reading_sessions': ['nope', '{}'],
    });
    final source = TarotLocalDataSource(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    expect(await source.fetchActive(), isNull);
    expect(await source.fetchAll(), isEmpty);
  });
}

ReadingContext _ctx({String question = ''}) {
  return ReadingContext.fromSession(_session(question: question));
}

AiReadingContent _emptyContent() {
  return const AiReadingContent(
    cardName: '',
    tagline: '',
    generalMeaning: '',
    love: '',
    career: '',
    money: '',
    spiritualGuidance: '',
    luckyEnergy: '',
    dailyAdvice: '',
    imageAsset: '',
    rarityColor: Color(0x00000000),
    fullInterpretation: '',
  );
}

ReadingSession _session({
  String question = 'Genel rehberlik',
  int cards = 3,
  ReadingFlowStep step = ReadingFlowStep.reading,
}) {
  final reveal = CardRevealSpread.forIndex(0);
  return ReadingSession(
    id: 'edge',
    deckId: 'classic',
    spread: TarotSpreadType.threeCard,
    intention: TarotIntention(text: question),
    shuffleSeed: 7,
    startedAt: DateTime(2026, 8, 19),
    flowStep: step,
    drawnCards: [
      for (var i = 0; i < cards; i++)
        TarotDrawnCard(
          card: reveal.card,
          positionIndex: i,
          isReversed: false,
          positionLabel: 'Şimdi',
        ),
    ],
  );
}
