/// OR-1170 — Seeded shuffle and draw pile management.
library;

import 'dart:math';

import '../../../../core/copy/resilience_copy.dart';
import '../models/tarot_card.dart';
import '../services/deck_service.dart';
import 'tarot_base_controller.dart';

class TarotDeckController extends TarotBaseController {
  TarotDeckController({DeckService? deckService})
      : _deckService = deckService ?? const DeckService();

  final DeckService _deckService;

  List<TarotCard> _deck = const [];
  List<TarotCard> _drawPile = const [];
  int? _shuffleSeed;
  String _deckId = 'rider-waite';
  bool _isShuffled = false;

  List<TarotCard> get deck => List.unmodifiable(_deck);
  List<TarotCard> get drawPile => List.unmodifiable(_drawPile);
  int? get shuffleSeed => _shuffleSeed;
  String get deckId => _deckId;
  bool get isShuffled => _isShuffled;
  int get remaining => _drawPile.length;

  Future<void> initializeDeck({
    required String deckId,
    int? seed,
  }) async {
    isLoading = true;
    clearError();
    try {
      _deckId = _deckService.resolveDeckId(deckId);
      _deck = _deckService.createDeck(deckId: _deckId);
      _shuffleSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
      _drawPile = _deckService.shuffledDeck(
        seed: _shuffleSeed!,
        deckId: _deckId,
      );
      _isShuffled = true;
    } catch (error) {
      errorMessage = ResilienceCopy.sessionInitFailed;
    } finally {
      isLoading = false;
    }
  }

  void restorePile({
    required String deckId,
    required int seed,
    required List<int> drawnCardIds,
  }) {
    _deckId = _deckService.resolveDeckId(deckId);
    _deck = _deckService.createDeck(deckId: _deckId);
    _shuffleSeed = seed;
    final shuffled = _deckService.shuffledDeck(seed: seed, deckId: _deckId);
    final drawnSet = drawnCardIds.toSet();
    _drawPile = shuffled.where((c) => !drawnSet.contains(c.id)).toList();
    _isShuffled = true;
    notifyListeners();
  }

  void shuffle({int? seed}) {
    if (_deck.isEmpty) return;
    _shuffleSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    _drawPile = _deckService.shuffledDeck(seed: _shuffleSeed!, deckId: _deckId);
    _isShuffled = true;
    notifyListeners();
  }

  ({TarotCard card, bool isReversed}) drawNext({Random? random}) {
    if (_drawPile.isEmpty) {
      throw StateError('Draw pile is empty');
    }
    final card = _drawPile.removeLast();
    final rng = random ?? Random(_shuffleSeed! + _drawPile.length);
    final isReversed = rng.nextBool();
    notifyListeners();
    return (card: card, isReversed: isReversed);
  }

  void resetPile() {
    if (_shuffleSeed == null) {
      _drawPile = List.from(_deck);
    } else {
      _drawPile = _deckService.shuffledDeck(seed: _shuffleSeed!, deckId: _deckId);
    }
    _isShuffled = _shuffleSeed != null;
    notifyListeners();
  }
}
