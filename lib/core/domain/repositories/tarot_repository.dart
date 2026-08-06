/// OR-1100 — Tarot repository interface.
library;

import '../models/deck.dart';
import '../models/tarot_card.dart';

abstract class TarotRepository {
  Future<List<DeckModel>> getDecks();
  Future<DeckModel?> getDeckById(String id);
  Future<List<TarotCardModel>> getMajorArcana();
  Future<TarotCardModel?> getCardById(int id);
  Future<void> saveSelectedDeckId(String deckId);
  Future<String?> getSelectedDeckId();
  Future<void> saveSelectedSpread(String spreadType);
  Future<String?> getSelectedSpread();
}
