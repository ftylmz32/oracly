/// Regression: canonical minor court order 11 Page, 12 Knight, 13 Queen, 14 King.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/content/tarot/data/tarot_content_catalogue.dart';
import 'package:oracly_new/features/content/tarot/data/tarot_court_legacy.dart';
import 'package:oracly_new/features/tarot/art/minor_arcana_art.dart';
import 'package:oracly_new/features/tarot/copy/tarot_l10n.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_data.dart';

void main() {
  const courtCases = <({String suit, int queenId, int kingId})>[
    (suit: 'cups', queenId: 34, kingId: 35),
    (suit: 'pentacles', queenId: 48, kingId: 49),
    (suit: 'swords', queenId: 62, kingId: 63),
    (suit: 'wands', queenId: 76, kingId: 77),
  ];

  setUp(() {
    OraclyL10n.bind('en');
  });

  test('catalogue court ranks are Queen at 13 and King at 14 for all suits', () {
    for (final c in courtCases) {
      final queen = TarotContentCatalogue.byId(c.queenId);
      final king = TarotContentCatalogue.byId(c.kingId);
      expect(queen.number, 13, reason: c.suit);
      expect(king.number, 14, reason: c.suit);
      expect(queen.name, contains('Queen'), reason: c.suit);
      expect(king.name, contains('King'), reason: c.suit);
      expect(queen.nameTr, contains('Krali\u00e7e'), reason: c.suit);
      expect(king.nameTr, contains('Kral'), reason: c.suit);
      expect(king.nameTr, isNot(contains('Krali\u00e7e')), reason: c.suit);
    }
  });

  test('runtime artwork maps rank 13 to queen file and rank 14 to king file', () {
    for (final c in courtCases) {
      final queen = TarotContentCatalogue.byId(c.queenId);
      final king = TarotContentCatalogue.byId(c.kingId);
      expect(queen.imageAsset, endsWith('14_queen_${c.suit}.webp'));
      expect(king.imageAsset, endsWith('13_king_${c.suit}.webp'));
      expect(MinorArcanaArt.assetFor(c.suit, 13), queen.imageAsset);
      expect(MinorArcanaArt.assetFor(c.suit, 14), king.imageAsset);
    }
  });

  test('l10n ritual ids match catalogue court identity', () {
    for (final c in courtCases) {
      expect(TarotL10n.cardName(c.queenId), contains('Queen'));
      expect(TarotL10n.cardName(c.kingId), contains('King'));
    }
  });

  test('destem bridge aligns with canonical court order without swap', () {
    for (final c in courtCases) {
      final queenBridge = OraclyTarotBridge.byRitualId(c.queenId)!;
      final kingBridge = OraclyTarotBridge.byRitualId(c.kingId)!;
      expect(queenBridge.name.en, contains('Queen'));
      expect(kingBridge.name.en, contains('King'));
      expect(queenBridge.id, endsWith('_13'));
      expect(kingBridge.id, endsWith('_14'));
      expect(
        OraclyTarotDeck.byId(queenBridge.id)!.name.en,
        queenBridge.name.en,
      );
    }
  });

  test('new draw serialization keeps name art and meaning aligned', () {
    for (final c in courtCases) {
      final queen = TarotContentCatalogue.byId(c.queenId);
      final king = TarotContentCatalogue.byId(c.kingId);
      expect(queen.keywords, contains('Kraliçe'));
      expect(king.keywords, contains('Kral'));
      expect(queen.uprightMeaning, contains('Krali\u00e7e'));
      expect(king.uprightMeaning, contains('Kral'));
      expect(king.uprightMeaning, isNot(contains('Krali\u00e7e')));
    }
  });

  test('legacy persisted court readings preserve original king/queen meaning', () {
    const legacyQueen = ReadingCardSnapshot(
      cardId: 35,
      cardName: 'Kupa Kraliçesi',
      cardImageAsset:
          'lib/assets/images/tarot/minor_arcana/cups/14_queen_cups.webp',
      positionIndex: 0,
    );
    const legacyKing = ReadingCardSnapshot(
      cardId: 34,
      cardName: 'Kupa Kralı',
      cardImageAsset:
          'lib/assets/images/tarot/minor_arcana/cups/13_king_cups.webp',
      positionIndex: 0,
    );

    final queenContent = TarotCourtLegacy.contentForSnapshot(legacyQueen);
    final kingContent = TarotCourtLegacy.contentForSnapshot(legacyKing);

    expect(queenContent.nameTr, contains('Krali\u00e7e'));
    expect(kingContent.nameTr, contains('Kral'));
    expect(TarotCourtLegacy.isLegacyCourtAsset(34, legacyKing.cardImageAsset), isTrue);
    expect(TarotCourtLegacy.isLegacyCourtAsset(35, legacyQueen.cardImageAsset), isTrue);
  });

  test('saved reading reopen uses legacy-aware catalogue lookup', () {
    const snapshot = ReadingCardSnapshot(
      cardId: 34,
      cardName: 'Kupa Kralı',
      cardImageAsset:
          'lib/assets/images/tarot/minor_arcana/cups/13_king_cups.webp',
      positionIndex: 0,
    );
    final entry = ReadingHistoryEntry(
      id: 'legacy-king',
      date: DateTime(2026, 1, 1),
      spreadType: 'Tek Kart',
      filter: HistorySpreadFilter.single,
      cardName: snapshot.cardName,
      cardImageAsset: snapshot.cardImageAsset,
      aiSummary: '',
      moodIcon: Icons.auto_awesome,
      cardIndex: snapshot.cardId,
      heroTag: 'legacy-king',
    );
    final model = ReadingModel(
      id: entry.id,
      cardId: snapshot.cardId,
      cardName: snapshot.cardName,
      cardImageAsset: snapshot.cardImageAsset,
      spreadType: entry.spreadType,
      aiSummary: entry.aiSummary,
      createdAt: entry.date,
      cards: const [snapshot],
    );

    final content = SavedReadingParser.toContent(entry: entry, model: model);
    expect(content.cardName, 'Kupa Kralı');
    expect(content.imageAsset, contains('13_king_cups'));
    expect(content.cardReadings, contains('Kral'));
    expect(content.cardReadings, isNot(contains('Krali\u00e7e Kupa')));
  });
}
