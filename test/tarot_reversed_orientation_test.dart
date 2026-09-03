/// Tarot drawn-card orientation consistency — live + saved history.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_builder.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';
import 'package:oracly_new/features/favorite_moments/presentation/widgets/favorite_moment_visual.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moment_factory.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_story_face.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_detail/card_detail_catalogue.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_detail/card_detail_hero_header.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/reveal_flip_front.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_data.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_list_card.dart';

TarotCard _card({
  int id = 17,
  String name = 'The Star',
  String image = 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
}) {
  return TarotCard(
    id: id,
    name: name,
    image: image,
    arcana: TarotArcana.major,
    suit: TarotSuit.none,
    number: id,
    summary: '',
    meaning: 'up',
    reversedMeaning: 'rev',
    keywords: const [],
  );
}

ReadingModel _model({
  required List<ReadingCardSnapshot> cards,
  String cardName = 'The Star',
  String asset = 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
  int cardId = 17,
}) {
  return ReadingModel(
    id: 'r1',
    cardId: cardId,
    cardName: cardName,
    cardImageAsset: asset,
    spreadType: 'Tek Kart',
    aiSummary: 'summary',
    createdAt: DateTime(2026, 8, 1),
    cards: cards,
  );
}

RevealCardData _reveal({required bool isReversed}) {
  final card = _card();
  return RevealCardData(
    card: card,
    displayName: card.name,
    subtitle: 's',
    rarityLabel: 'Major',
    rarityColor: Colors.purple,
    imageAsset: card.image,
    isReversed: isReversed,
  );
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await OraclyFormat.ensureInitialized();
  });
  setUp(() => OraclyL10n.bind(AppLocale.tr));
  tearDown(() => OraclyL10n.bind(AppLocale.tr));

  test('primaryIsReversed derives from matching card snapshot', () {
    final upright = _model(
      cards: [
        const ReadingCardSnapshot(
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
          positionIndex: 0,
        ),
      ],
    );
    final reversed = _model(
      cards: [
        const ReadingCardSnapshot(
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
          positionIndex: 0,
          isReversed: true,
        ),
      ],
    );
    final legacy = _model(cards: const []);
    expect(upright.primaryIsReversed, isFalse);
    expect(reversed.primaryIsReversed, isTrue);
    expect(legacy.primaryIsReversed, isFalse);
  });

  test('mapper propagates primary orientation; reopen is stable', () {
    final model = _model(
      cards: [
        const ReadingCardSnapshot(
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
          positionIndex: 0,
          isReversed: true,
        ),
      ],
    );
    final a = ReadingHistoryMapper.fromModel(model);
    final b = ReadingHistoryMapper.fromModel(model);
    expect(a.isReversed, isTrue);
    expect(b.isReversed, isTrue);
    expect(a.isReversed, b.isReversed);
  });

  test('multi-card snapshots keep independent orientations', () {
    final model = _model(
      cardId: 0,
      cardName: 'The Fool',
      asset: 'lib/assets/images/tarot/major_arcana/00_aptal.png',
      cards: const [
        ReadingCardSnapshot(
          cardId: 0,
          cardName: 'The Fool',
          cardImageAsset: 'lib/assets/images/tarot/major_arcana/00_aptal.png',
          positionIndex: 0,
        ),
        ReadingCardSnapshot(
          cardId: 1,
          cardName: 'The Magician',
          cardImageAsset: 'lib/assets/images/tarot/major_arcana/01_buyucu.png',
          positionIndex: 1,
          isReversed: true,
        ),
        ReadingCardSnapshot(
          cardId: 2,
          cardName: 'The High Priestess',
          cardImageAsset: 'lib/assets/images/tarot/major_arcana/02_azize.png',
          positionIndex: 2,
        ),
      ],
    );
    expect(model.primaryIsReversed, isFalse);
    expect(model.cards.map((c) => c.isReversed).toList(), [false, true, false]);

    final entry = ReadingHistoryMapper.fromModel(model);
    final content = SavedReadingParser.toContent(entry: entry, model: model);
    expect(content.drawnCards.map((c) => c.isReversed).toList(), [
      false,
      true,
      false,
    ]);
    final faces = ReadingStoryFaceSpec.of(content);
    expect(faces.map((f) => f.isReversed).toList(), [false, true, false]);
  });

  test('old saved reading without cards defaults upright in parser', () {
    final model = _model(cards: const []);
    final entry = ReadingHistoryMapper.fromModel(model);
    expect(entry.isReversed, isFalse);
    final content = SavedReadingParser.toContent(entry: entry, model: model);
    expect(content.drawnCards.single.isReversed, isFalse);
  });

  testWidgets('upright live reveal does not rotate by pi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RevealFlipFront(
            data: _reveal(isReversed: false),
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

  testWidgets('reversed live reveal rotates by pi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RevealFlipFront(
            data: _reveal(isReversed: true),
            width: 120,
            height: 186,
            goldOpacity: 1,
            artOpacity: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(_hasRotatePi(tester), isTrue);
  });

  testWidgets('saved reversed history list card rotates by pi', (tester) async {
    final entry = ReadingHistoryEntry(
      id: 'h',
      date: DateTime(2026, 8, 1),
      spreadType: 'Tek Kart',
      filter: HistorySpreadFilter.single,
      cardName: 'The Star',
      cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
      aiSummary: 'x',
      moodIcon: Icons.star,
      cardIndex: 17,
      heroTag: 't',
      isReversed: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingHistoryListCard(
            entry: entry,
            entrance: 1,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(_hasRotatePi(tester), isTrue);
  });

  testWidgets('saved upright history list card stays upright', (tester) async {
    final entry = ReadingHistoryEntry(
      id: 'h',
      date: DateTime(2026, 8, 1),
      spreadType: 'Tek Kart',
      filter: HistorySpreadFilter.single,
      cardName: 'The Star',
      cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
      aiSummary: 'x',
      moodIcon: Icons.star,
      cardIndex: 17,
      heroTag: 't',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingHistoryListCard(
            entry: entry,
            entrance: 1,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(_hasRotatePi(tester), isFalse);
  });

  testWidgets('catalogue card-detail hero remains upright', (tester) async {
    final content = CardDetailCatalogue.all.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: CardDetailHeroHeader(
              content: content,
              scrollOffset: 0,
              isFavorite: false,
              onBack: () {},
              onFavorite: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(_hasRotatePi(tester), isFalse);
  });

  test('story face specs preserve live drawn orientations across rebuild', () {
    final drawn = [
      TarotDrawnCard(card: _card(id: 0), positionIndex: 0, isReversed: true),
      TarotDrawnCard(card: _card(id: 1), positionIndex: 1, isReversed: false),
    ];
    for (var i = 0; i < 2; i++) {
      final specs = [
        for (final c in drawn)
          ReadingStoryFaceSpec(
            imageAsset: c.card.image,
            name: c.card.name,
            position: 'p',
            isReversed: c.isReversed,
            rarityColor: Colors.amber,
          ),
      ];
      expect(specs[0].isReversed, isTrue);
      expect(specs[1].isReversed, isFalse);
    }
  });

  test('favorite factory preserves drawn orientation; legacy upright', () {
    final reversed = _model(
      cards: [
        const ReadingCardSnapshot(
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
          positionIndex: 0,
          isReversed: true,
        ),
      ],
    );
    final upright = _model(
      cards: [
        const ReadingCardSnapshot(
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
          positionIndex: 0,
        ),
      ],
    );
    final legacy = _model(cards: const []);
    expect(FavoriteMomentFactory.tarot(reversed).visualIsReversed, isTrue);
    expect(FavoriteMomentFactory.tarot(upright).visualIsReversed, isFalse);
    expect(FavoriteMomentFactory.tarot(legacy).visualIsReversed, isFalse);
    expect(
      FavoriteMomentFactory.tarotLive(
        sessionId: 's',
        at: DateTime(2026, 8, 1),
        cardName: 'The Star',
        cardAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
        insight: 'x',
        isReversed: true,
      ).visualIsReversed,
      isTrue,
    );
    final json = FavoriteMomentFactory.tarot(reversed).toJson();
    expect(FavoriteMoment.fromJson(json).visualIsReversed, isTrue);
    final uprightJson = FavoriteMomentFactory.tarot(upright).toJson();
    expect(uprightJson.containsKey('visualIsReversed'), isFalse);
    expect(FavoriteMoment.fromJson(uprightJson).visualIsReversed, isFalse);
  });

  test('drawn-card share carries orientation; catalogue share stays upright', () {
    final drawn = DiscoveryShareBuilder.tarot(
      cardName: 'The Star',
      cardAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
      isReversed: true,
    );
    final catalogue = DiscoveryShareBuilder.tarot(
      cardName: 'The Star',
      cardAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
    );
    expect(drawn.visualIsReversed, isTrue);
    expect(catalogue.visualIsReversed, isFalse);
  });

  testWidgets('favorite visual rotates when visualIsReversed', (tester) async {
    final moment = FavoriteMoment(
      id: 't:1',
      source: FavoriteMomentSource.tarot,
      sourceRef: '1',
      savedAt: DateTime(2026, 8, 1),
      occurredAt: DateTime(2026, 8, 1),
      quote: 'q',
      visualAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
      visualLabel: 'The Star',
      visualIsReversed: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FavoriteMomentVisual(moment: moment)),
      ),
    );
    await tester.pump();
    expect(_hasRotatePi(tester), isTrue);
  });
}