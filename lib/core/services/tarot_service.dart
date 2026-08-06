/// OR-1100 — Tarot flow service.
library;

import '../domain/models/deck.dart';
import '../domain/models/tarot_card.dart';
import '../domain/repositories/tarot_repository.dart';

class TarotService {
  TarotService(this._repository);

  final TarotRepository _repository;

  Future<List<DeckModel>> getDecks() => _repository.getDecks();

  Future<List<TarotCardModel>> getMajorArcana() => _repository.getMajorArcana();

  Future<void> selectDeck(String deckId) => _repository.saveSelectedDeckId(deckId);

  Future<void> selectSpread(String spreadType) =>
      _repository.saveSelectedSpread(spreadType);

  Future<String?> selectedDeckId() => _repository.getSelectedDeckId();

  Future<String?> selectedSpread() => _repository.getSelectedSpread();
}
