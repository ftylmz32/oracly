/// OR-1100 — Mock tarot repository with local persistence.
library;

import '../../domain/models/deck.dart';
import '../../domain/models/tarot_card.dart';
import '../../domain/repositories/tarot_repository.dart';
import '../datasources/local_storage.dart';

class MockTarotRepository implements TarotRepository {
  MockTarotRepository(this._storage);

  final LocalStorage _storage;

  static const _deckKey = 'or_selected_deck';
  static const _spreadKey = 'or_selected_spread';
  static const _root = 'lib/assets/images/cards/tarot/major';

  static const _decks = [
    DeckModel(
      id: 'rider-waite',
      name: 'Rider-Waite',
      description: 'Klasik sembolizm ve evrensel yorum.',
      imageAsset: '$_root/00-TheFool.png',
      isPremium: false,
    ),
    DeckModel(
      id: 'oracly-gold',
      name: 'OR Gold Edition',
      description: 'Altın detaylı premium deste.',
      imageAsset: '$_root/17-TheStar.png',
      isPremium: true,
    ),
    DeckModel(
      id: 'mystic-moon',
      name: 'Mystic Moon',
      description: 'Ay enerjisiyle dokunmuş özel deste.',
      imageAsset: '$_root/18-TheMoon.png',
      isPremium: true,
    ),
  ];

  static final _majorCards = <TarotCardModel>[
    for (final e in _majorMeta)
      TarotCardModel(
        id: e.$1,
        name: e.$2,
        nameTr: e.$3,
        imageAsset: '$_root/${e.$4}',
        arcana: TarotArcanaType.major,
        suit: TarotSuitType.none,
        number: e.$1,
        keywords: ['Sezgi', 'Yolculuk', 'Dönüşüm'],
        summary: '${e.$3} kartının derin mistik anlamı.',
      ),
  ];

  static const _majorMeta = [
    (0, 'The Fool', 'Deli', '00-TheFool.png'),
    (1, 'The Magician', 'Büyücü', '01-TheMagician.png'),
    (2, 'The High Priestess', 'Başrahibe', '02-TheHighPriestess.png'),
    (3, 'The Empress', 'İmparatoriçe', '03-TheEmpress.png'),
    (4, 'The Emperor', 'İmparator', '04-TheEmperor.png'),
    (5, 'The Hierophant', 'Aziz', '05-TheHierophant.png'),
    (6, 'The Lovers', 'Aşıklar', '06-TheLovers.png'),
    (7, 'The Chariot', 'Savaş Arabası', '07-TheChariot.png'),
    (8, 'Strength', 'Güç', '08-Strength.png'),
    (9, 'The Hermit', 'Ermiş', '09-TheHermit.png'),
    (10, 'Wheel of Fortune', 'Kader Çarkı', '10-WheelOfFortune.png'),
    (11, 'Justice', 'Adalet', '11-Justice.png'),
    (12, 'The Hanged Man', 'Asılan Adam', '12-TheHangedMan.png'),
    (13, 'Death', 'Ölüm', '13-Death.png'),
    (14, 'Temperance', 'Denge', '14-Temperance.png'),
    (15, 'The Devil', 'Şeytan', '15-TheDevil.png'),
    (16, 'The Tower', 'Kule', '16-TheTower.png'),
    (17, 'The Star', 'Yıldız', '17-TheStar.png'),
    (18, 'The Moon', 'Ay', '18-TheMoon.png'),
    (19, 'The Sun', 'Güneş', '19-TheSun.png'),
    (20, 'Judgement', 'Mahkeme', '20-Judgement.png'),
    (21, 'The World', 'Dünya', '21-TheWorld.png'),
  ];

  @override
  Future<List<DeckModel>> getDecks() async => _decks;

  @override
  Future<DeckModel?> getDeckById(String id) async {
    for (final d in _decks) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Future<List<TarotCardModel>> getMajorArcana() async => _majorCards;

  @override
  Future<TarotCardModel?> getCardById(int id) async {
    if (id < 0 || id >= _majorCards.length) return null;
    return _majorCards[id];
  }

  @override
  Future<void> saveSelectedDeckId(String deckId) =>
      _storage.setString(_deckKey, deckId);

  @override
  Future<String?> getSelectedDeckId() async => _storage.getString(_deckKey);

  @override
  Future<void> saveSelectedSpread(String spreadType) =>
      _storage.setString(_spreadKey, spreadType);

  @override
  Future<String?> getSelectedSpread() async => _storage.getString(_spreadKey);
}
