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

  static const int fanLimit = 7;

  int get visibleFanCount {
    final n = _drawPile.length;
    if (n <= 0) return 0;
    return n < fanLimit ? n : fanLimit;
  }

  /// Face-down fan — the actual remaining cards at the top of the pile.
  List<TarotCard> get fanCards {
    final n = visibleFanCount;
    if (n == 0) return const [];
    return List.unmodifiable(_drawPile.sublist(_drawPile.length - n));
  }

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
    final isReversed = random?.nextBool() ?? _orientationOf(card);
    notifyListeners();
    return (card: card, isReversed: isReversed);
  }

  /// Draw the face-down fan slot the user actually touched.
  ({TarotCard card, bool isReversed}) drawFromFan(int fanIndex) {
    final n = visibleFanCount;
    if (fanIndex < 0 || fanIndex >= n) {
      throw RangeError.index(fanIndex, List<int>.filled(n, 0));
    }
    final pileIndex = _drawPile.length - n + fanIndex;
    final card = _drawPile.removeAt(pileIndex);
    final isReversed = _orientationOf(card);
    notifyListeners();
    return (card: card, isReversed: isReversed);
  }

  /// Frozen at draw — never re-rolled after reveal.
  bool _orientationOf(TarotCard card) {
    final seed = _shuffleSeed ?? 0;
    return Random(seed ^ card.id ^ (_drawPile.length * 17)).nextBool();
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
