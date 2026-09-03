/// Tarot Upright V1 — no random reversed production draws.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_deck_controller.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_story_face.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/reveal_flip_front.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_card_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _hasRotatePi(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(find.byType(Transform));
  for (final t in transforms) {
    final m = t.transform;
    if ((m.storage[0] + 1).abs() < 0.01 && (m.storage[5] + 1).abs() < 0.01) {
      return true;
    }
  }
  return false;
}

Future<TarotReadingController> _reading() async {
  SharedPreferences.setMockInitialValues({});
  return TarotReadingController(
    repository: TarotReadingRepositoryImpl.fromStorage(
      LocalStorage(await SharedPreferences.getInstance()),
    ),
  );
}

Future<void> _toSelection(TarotReadingController reading) async {
  await reading.advanceToShuffle();
  await reading.performShuffle();
  await reading.finishShuffle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  group('canonical draw state', () {
    test('drawNext produces upright production draw', () async {
      final deck = TarotDeckController();
      await deck.initializeDeck(deckId: 'classic', seed: 3);
      for (var i = 0; i < 20; i++) {
        if (deck.remaining == 0) break;
        expect(deck.drawNext().isReversed, isFalse);
      }
    });

    test('drawFromFan produces upright production draw', () async {
      for (var i = 0; i < TarotDeckController.fanLimit; i++) {
        final deck = TarotDeckController();
        await deck.initializeDeck(deckId: 'classic', seed: 5);
        expect(deck.drawFromFan(i).isReversed, isFalse);
      }
    });

    test('single-card session draw is upright', () async {
      final reading = await _reading();
      addTearDown(reading.dispose);
      await reading.beginSession(
        spread: TarotSpreadType.single,
        deckId: 'classic',
      );
      await _toSelection(reading);
      final drawn = await reading.drawCard();
      expect(drawn.isReversed, isFalse);
      expect(reading.session!.drawnCards.single.isReversed, isFalse);
    });

    test('multi-card session draws are upright', () async {
      final reading = await _reading();
      addTearDown(reading.dispose);
      await reading.beginSession(
        spread: TarotSpreadType.threeCard,
        deckId: 'classic',
      );
      await _toSelection(reading);
      await reading.drawAllRemaining();
      expect(
        reading.session!.drawnCards.map((c) => c.isReversed).toList(),
        [false, false, false],
      );
    });

    test('shuffle rebuild navigation does not re-randomize orientation', () async {
      final reading = await _reading();
      addTearDown(reading.dispose);
      await reading.beginSession(
        spread: TarotSpreadType.threeCard,
        deckId: 'classic',
      );
      await _toSelection(reading);
      final first = await reading.drawCard(fanIndex: 1);
      await reading.performShuffle();
      await reading.performShuffle();
      expect(reading.session!.drawnCards.single.isReversed, first.isReversed);
      expect(first.isReversed, isFalse);
    });
  });

  group('visual surfaces for new draws', () {
    testWidgets('reveal artwork is not rotated by normal new draw', (tester) async {
      final reading = await _reading();
      addTearDown(reading.dispose);
      await reading.beginSession(
        spread: TarotSpreadType.single,
        deckId: 'classic',
      );
      await _toSelection(reading);
      final drawn = await reading.drawCard();
      final reveal = RevealCardData.fromDrawnCard(drawn);
      expect(reveal.isReversed, isFalse);
      expect(reveal.subtitle, contains(TarotPolishCopy.upright));
      expect(reveal.subtitle, isNot(contains(TarotPolishCopy.reversed)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RevealFlipFront(
              data: reveal,
              width: 120,
              height: 186,
              goldOpacity: 1,
              artOpacity: 1,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_hasRotatePi(tester), isFalse);
    });

    testWidgets('ritual card face stays upright for new draw', (tester) async {
      final reading = await _reading();
      addTearDown(reading.dispose);
      await reading.beginSession(
        spread: TarotSpreadType.single,
        deckId: 'classic',
      );
      await _toSelection(reading);
      final drawn = await reading.drawCard();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RitualCardFace(
              label: drawn.localizedName,
              image: drawn.card.image,
              reversed: drawn.isReversed,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_hasRotatePi(tester), isFalse);
    });

    test('result story face is upright for new multi-card draw', () async {
      final reading = await _reading();
      addTearDown(reading.dispose);
      await reading.beginSession(
        spread: TarotSpreadType.threeCard,
        deckId: 'classic',
      );
      await _toSelection(reading);
      await reading.drawAllRemaining();
      final session = reading.session!;
      final content = AiReadingContent(
        cardName: session.drawnCards.first.localizedName,
        tagline: '',
        generalMeaning: '',
        love: '',
        career: '',
        money: '',
        spiritualGuidance: '',
        luckyEnergy: '',
        dailyAdvice: '',
        imageAsset: session.drawnCards.first.card.image,
        rarityColor: Colors.purple,
        drawnCards: session.drawnCards,
      );
      final specs = ReadingStoryFaceSpec.of(content);
      expect(specs.every((s) => !s.isReversed), isTrue);
      expect(
        specs.every((s) => s.orientation == TarotPolishCopy.upright),
        isTrue,
      );
    });
  });

  group('persistence', () {
    test('new saved session persists isReversed=false', () async {
      final reading = await _reading();
      addTearDown(reading.dispose);
      await reading.beginSession(
        spread: TarotSpreadType.threeCard,
        deckId: 'classic',
      );
      await _toSelection(reading);
      await reading.drawCard();
      await reading.flush();
      final json = reading.session!.toJson();
      expect(json['drawnCards'][0]['isReversed'], isFalse);
    });

    test('reopen does not change orientation', () async {
      final reading = await _reading();
      addTearDown(reading.dispose);
      await reading.beginSession(
        spread: TarotSpreadType.single,
        deckId: 'classic',
      );
      await _toSelection(reading);
      await reading.drawCard();
      final before = reading.session!.drawnCards.single.isReversed;
      await reading.flush();

      final restored = TarotReadingController(
        repository: TarotReadingRepositoryImpl.fromStorage(
          LocalStorage(await SharedPreferences.getInstance()),
        ),
      );
      addTearDown(restored.dispose);
      await restored.restoreActiveSession();
      expect(restored.session, isNotNull);
      expect(restored.session!.drawnCards.single.isReversed, before);
      expect(before, isFalse);
    });

    test('old persisted reversed reading still loads safely', () {
      final model = ReadingModel(
        id: 'legacy',
        cardId: 18,
        cardName: 'The Moon',
        cardImageAsset: 'moon.png',
        spreadType: 'Uc Kart',
        aiSummary: 'legacy',
        createdAt: DateTime(2026, 1, 1),
        cards: const [
          ReadingCardSnapshot(
            cardId: 18,
            cardName: 'The Moon',
            cardImageAsset: 'moon.png',
            positionIndex: 1,
            isReversed: true,
          ),
        ],
      );
      final entry = ReadingHistoryMapper.fromModel(model);
      final content = SavedReadingParser.toContent(entry: entry, model: model);
      expect(entry.isReversed, isTrue);
      expect(content.drawnCards.single.isReversed, isTrue);
      expect(
        ReadingStoryFaceSpec.of(content).single.orientation,
        TarotPolishCopy.reversed,
      );
    });
  });

  test('Asilan Adam upright draw keeps card upright', () async {
    final deck = TarotDeckController();
    await deck.initializeDeck(deckId: 'classic', seed: 42);
    TarotDrawnCard? hanged;
    while (deck.remaining > 0) {
      final draw = deck.drawNext();
      if (draw.card.id == 12) {
        hanged = TarotDrawnCard(
          card: draw.card,
          positionIndex: 0,
          isReversed: draw.isReversed,
        );
        break;
      }
    }
    expect(hanged, isNotNull);
    expect(hanged!.isReversed, isFalse);
    expect(hanged.effectiveMeaning, hanged.card.meaning);
    expect(hanged.card.id, 12);
    final reveal = RevealCardData.fromDrawnCard(hanged);
    expect(reveal.isReversed, isFalse);
    expect(reveal.imageAsset, contains('12_asilan'));
  });
}
