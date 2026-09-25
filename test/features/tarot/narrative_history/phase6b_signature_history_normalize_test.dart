/// Phase 6B — Crossroads historical FACT normalization (never fiveCard).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_00.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_input.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_card_recurrence_engine.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_history_card_normalize.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_history_legacy_normalize.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_history_session_normalize.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_history_source_adapter.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_recurrence_context.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_history_spread_normalizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tarot_4c_test_support.dart';
import 'tarot_history_test_support.dart';

const _keys = ['option_a', 'option_b', 'tension', 'counsel', 'direction'];

TarotCard _card(int id) => TarotCard(
  id: id,
  name: 'Card $id',
  image: 'c$id.png',
  arcana: TarotArcana.major,
  suit: TarotSuit.none,
  number: id,
  summary: 's',
  meaning: 'm',
  reversedMeaning: 'r',
  keywords: const ['k'],
);

ReadingSession _crossroadsSession({
  String id = 'sess-cr',
  String? userId,
  bool omitKeys = false,
  String? interpretation = 'Stored interpretation.',
}) {
  final at = DateTime.utc(2026, 9, 22, 12);
  return ReadingSession(
    id: id,
    deckId: 'rider-waite',
    userId: userId,
    spread: TarotSpreadType.crossroads,
    intention: const TarotIntention(text: 'Which path feels honest?'),
    shuffleSeed: 1,
    status: ReadingSessionStatus.completed,
    startedAt: at,
    completedAt: at,
    drawnCards: [
      for (var i = 0; i < 5; i++)
        TarotDrawnCard(
          card: _card(i),
          isReversed: false,
          positionIndex: i,
          positionKey: omitKeys ? null : _keys[i],
        ),
    ],
    interpretation: interpretation,
  );
}

ReadingModel _crossroadsLegacy({
  required String spreadType,
  String id = 'legacy-cr',
  String? userId,
}) {
  return ReadingModel(
    id: id,
    cardId: 0,
    cardName: 'The Fool',
    cardImageAsset: 'fool.png',
    spreadType: spreadType,
    aiSummary: 'Stored summary.',
    createdAt: DateTime.utc(2026, 9, 22),
    userId: userId,
    cards: [
      for (var i = 0; i < 5; i++)
        ReadingCardSnapshot(
          cardId: i,
          cardName: 'Card $i',
          cardImageAsset: 'c$i.png',
          isReversed: false,
          positionIndex: i,
        ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('supported history resolution', () {
    test('classicalFromSpread(crossroads) remains null', () {
      expect(
        TarotHistoryCardNormalize.classicalFromSpread(
          TarotSpreadType.crossroads,
        ),
        isNull,
      );
    });

    test('supported Crossroads identity', () {
      final s = TarotHistoryCardNormalize.supportedFromSpread(
        TarotSpreadType.crossroads,
      )!;
      expect(s.spreadId, 'signature.crossroads');
      expect(s.legacyTypeName, 'crossroads');
      expect(s.cardCount, 5);
      expect(
        s.positions.map((p) => p.positionKey).toList(),
        _keys,
      );
      expect(
        SignatureHistorySpreadNormalizer.fromSpread(TarotSpreadType.threeCard),
        isNull,
      );
    });

    test('persisted machine/TR/EN/RU → signature.crossroads', () {
      for (final raw in [
        'crossroads',
        'Crossroads',
        'Yol Ayrımı',
        'Перекрёсток',
        'перекресток',
      ]) {
        final s = TarotHistoryCardNormalize.supportedFromPersisted(raw);
        expect(s?.spreadId, 'signature.crossroads', reason: raw);
      }
    });

    test('unknown spread still fails closed', () {
      expect(
        TarotHistoryCardNormalize.supportedFromPersisted('garbage_spread'),
        isNull,
      );
    });
  });

  group('session + legacy normalize', () {
    test('Crossroads session → signature.crossroads positions', () {
      final result = TarotHistorySessionNormalize.normalize(
        session: _crossroadsSession(omitKeys: true),
        linked: null,
        currentOwnerId: null,
      );
      expect(result.record, isNotNull);
      expect(result.record!.spreadId, 'signature.crossroads');
      expect(result.record!.spreadId, isNot('classical.fiveCard'));
      expect(result.record!.cards, hasLength(5));
      expect(
        result.record!.cards.map((c) => c.positionKey).toList(),
        _keys,
      );
      expect(result.liveSourceIds, {'sess-cr'});
      expect(result.diag.skippedMalformed, 0);
    });

    test('Crossroads legacy titles normalize', () {
      for (final title in [
        'crossroads',
        'Crossroads',
        'Yol Ayrımı',
        'Перекрёсток',
      ]) {
        final result = TarotHistoryLegacyNormalize.normalize(
          reading: _crossroadsLegacy(spreadType: title),
          currentOwnerId: null,
        );
        expect(result.record?.spreadId, 'signature.crossroads', reason: title);
        expect(result.record!.cards, hasLength(5));
        expect(
          result.record!.cards.map((c) => c.positionKey).toList(),
          _keys,
        );
        expect(result.record!.cards.every((c) => !c.orientationKnown), isTrue);
      }
    });

    test('owner isolation for Crossroads', () {
      final ok = TarotHistorySessionNormalize.normalize(
        session: _crossroadsSession(userId: 'A'),
        linked: null,
        currentOwnerId: 'A',
      );
      expect(ok.record, isNotNull);

      final bad = TarotHistorySessionNormalize.normalize(
        session: _crossroadsSession(id: 'sess-b', userId: 'B'),
        linked: null,
        currentOwnerId: 'A',
      );
      expect(bad.record, isNull);
      expect(bad.diag.skippedOwnerMismatch, 1);

      final orphan = TarotHistorySessionNormalize.normalize(
        session: _crossroadsSession(id: 'sess-o', userId: null),
        linked: null,
        currentOwnerId: 'A',
      );
      expect(orphan.record, isNull);
      expect(orphan.diag.skippedOwnerMismatch, 1);
    });

    test('linked session + journal dedupe', () {
      final session = _crossroadsSession(id: 'linked-cr');
      final journal = ReadingModel(
        id: 'linked-cr',
        cardId: 0,
        cardName: 'The Fool',
        cardImageAsset: 'fool.png',
        spreadType: 'crossroads',
        aiSummary: 'Journal summary.',
        createdAt: DateTime.utc(2026, 9, 22),
        sessionId: 'linked-cr',
        intention: 'Enriched question?',
        readingType: 'decision',
        cards: [
          for (var i = 0; i < 5; i++)
            ReadingCardSnapshot(
              cardId: i,
              cardName: 'Card $i',
              cardImageAsset: 'c$i.png',
              isReversed: false,
              positionIndex: i,
            ),
        ],
      );
      final result = TarotHistorySessionNormalize.normalize(
        session: session,
        linked: journal,
        currentOwnerId: null,
      );
      expect(result.record, isNotNull);
      expect(result.record!.spreadId, 'signature.crossroads');
      expect(result.linkedReadingIds, {'linked-cr'});
      expect(result.liveSourceIds, {'linked-cr'});
      expect(result.record!.topicId, 'decision');
    });

    test('classical session still classical.single', () {
      final result = TarotHistorySessionNormalize.normalize(
        session: completedSession(id: 'classic-s'),
        linked: null,
        currentOwnerId: null,
      );
      expect(result.record!.spreadId, 'classical.single');
    });
  });

  group('source adapter + snapshot + recurrence', () {
    late LocalStorage storage;
    late MockHistoryRepository repo;
    late HistoryService history;
    late TarotReadingRepositoryImpl tarot;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorage(await SharedPreferences.getInstance());
      repo = MockHistoryRepository(storage);
      history = HistoryService(repo);
      tarot = TarotReadingRepositoryImpl.fromStorage(storage);
    });

    test('source adapter Crossroads E2E', () async {
      await tarot.saveSession(_crossroadsSession(id: 'src-cr'));
      final loaded = await TarotHistorySourceAdapter(
        history: history,
        tarotRepository: tarot,
      ).load(currentOwnerId: null);
      expect(loaded.readings, hasLength(1));
      expect(loaded.readings.single.spreadId, 'signature.crossroads');
      expect(loaded.liveTarotSourceIds, contains('src-cr'));
      expect(loaded.diagnostics.skippedMalformed, 0);
    });

    test('snapshot loader Crossroads + privacy', () async {
      final h = Phase4cHarness(storage);
      await setOwner(h.storage, null);
      await h.tarot.saveSession(_crossroadsSession(id: 'snap-cr'));
      final ok = await h.loader().load(currentOwnerId: null);
      expect(ok.privacyBlocked, isFalse);
      expect(ok.snapshot.tarotReadings.single.spreadId, 'signature.crossroads');

      await setOwner(h.storage, 'A');
      await h.tarot.saveSession(
        _crossroadsSession(id: 'snap-a', userId: 'A'),
      );
      final blocked = await h.loader().load(currentOwnerId: 'B');
      expect(blocked.privacyBlocked, isTrue);
      expect(blocked.snapshot.tarotReadings, isEmpty);
    });

    test('card recurrence from Crossroads history', () {
      final base = baseRequest();
      final hist = histReading(
        readingId: 'h-cr',
        at: nowFixed.subtract(const Duration(days: 2)),
        spreadId: 'signature.crossroads',
        cardId: major00,
        positionKey: 'tension',
        positionIndex: 2,
        topicId: 'career',
        intentionSummary: 'Should I stay in this relationship?',
      );
      final result = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(tarotReadings: [hist]),
        currentOwnerId: null,
        now: nowFixed,
      );
      expect(result.recurringCards, hasLength(1));
      final sample = result.recurringCards.single.occurrences.single;
      expect(sample.spreadId, 'signature.crossroads');
      expect(sample.positionKey, 'tension');
    });

    test('same-spread alone does not authorize recurrence overlap', () {
      final hist = histReading(
        readingId: 'h-cr2',
        at: nowFixed.subtract(const Duration(days: 1)),
        spreadId: 'signature.crossroads',
        cardId: major00,
        positionKey: 'option_a',
        topicId: null,
        questionKind: QuestionKind.open,
        intentionSummary: null,
      );
      final q = const QuestionGrounding(
        rawText: null,
        topic: null,
        kind: QuestionKind.open,
        hasRealQuestion: false,
      );
      final m = TarotRecurrenceContext.evaluate(
        currentQuestion: q,
        currentCards: [cardEvidence(kNarrativeMajor00, positionIndex: 0)],
        historical: hist,
        matchedOccurrence: hist.cards.single,
      );
      expect(m.overlaps, isFalse);
    });
  });

  test('default Classical builder still rejects Crossroads', () {
    expect(
      () => NarrativeEvidenceBuilder.build(
        NarrativeEvidenceInput(
          sessionId: 's',
          readingId: 'r',
          languageCode: 'en',
          spreadType: TarotSpreadType.crossroads,
          cards: [
            for (var i = 0; i < 5; i++)
              NarrativeEvidenceCardInput(
                canonicalCardId: 'major_0$i',
                ritualCardId: i,
                isReversed: false,
                positionKey: 'situation',
                positionIndex: i,
              ),
          ],
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
