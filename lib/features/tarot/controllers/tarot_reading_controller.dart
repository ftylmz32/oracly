/// OR-1170 — Tarot reading session controller.
library;

import '../../../../core/copy/resilience_copy.dart';
import '../domain/models/reading_session.dart';
import '../../insights/models/journey_personalization_hints.dart';
import '../domain/models/tarot_position.dart';
import '../domain/models/tarot_spread.dart';
import '../domain/repositories/tarot_reading_repository.dart';
import '../presentation/widgets/ai_reading/ai_reading_content.dart';
import '../services/tarot_interpretation_service.dart';
import 'tarot_base_controller.dart';
import 'tarot_deck_controller.dart';

class TarotReadingController extends TarotBaseController {
  TarotReadingController({
    TarotReadingRepository? repository,
    TarotDeckController? deckController,
    TarotInterpretationService? interpretationService,
  })  : _repository = repository ??
            (throw ArgumentError('TarotReadingRepository is required')),
        _deckController = deckController ?? TarotDeckController(),
        _interpretationService =
            interpretationService ?? TarotInterpretationService();

  final TarotReadingRepository _repository;
  final TarotDeckController _deckController;
  final TarotInterpretationService _interpretationService;

  ReadingSession? _session;

  ReadingSession? get session => _session;
  TarotDeckController get deckController => _deckController;

  Future<void> restoreActiveSession() async {
    final active = await _repository.loadActiveSession();
    if (active == null) return;
    _session = active;
    _deckController.restorePile(
      deckId: active.deckId,
      seed: active.shuffleSeed,
      drawnCardIds: active.drawnCards.map((c) => c.card.id).toList(),
    );
    notifyListeners();
  }

  Future<ReadingSession> beginSession({
    required TarotSpreadType spread,
    required String deckId,
    TarotIntention intention = const TarotIntention(text: ''),
    String? userId,
  }) async {
    isLoading = true;
    clearError();
    try {
      final seed = DateTime.now().millisecondsSinceEpoch;
      await _deckController.initializeDeck(deckId: deckId, seed: seed);
      _session = ReadingSession(
        id: 'session_$seed',
        deckId: _deckController.deckId,
        userId: userId,
        spread: spread,
        intention: intention,
        shuffleSeed: seed,
        startedAt: DateTime.now(),
        flowStep: ReadingFlowStep.deckSelection,
      );
      await _persist();
      return _session!;
    } catch (error) {
      errorMessage = ResilienceCopy.sessionInitFailed;
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  Future<void> advanceToShuffle() async {
    await _updateStep(ReadingFlowStep.shuffle);
  }

  Future<void> performShuffle() async {
    final current = _session;
    if (current == null) return;
    _deckController.shuffle(seed: current.shuffleSeed);
    await _updateStep(ReadingFlowStep.cardSelection);
  }

  Future<TarotDrawnCard> drawCard() async {
    final current = _session;
    if (current == null) {
      throw StateError('No active reading session');
    }
    if (current.allCardsDrawn) {
      throw StateError('All cards already drawn');
    }

    final draw = _deckController.drawNext();
    final position = SpreadService.positionAt(
      current.spread,
      current.drawnCards.length,
    );
    final drawn = TarotDrawnCard(
      card: draw.card,
      positionIndex: current.drawnCards.length,
      isReversed: draw.isReversed,
      positionLabel: position?.labelTr,
      positionKey: position?.key,
    );

    _session = current.copyWith(
      drawnCards: [...current.drawnCards, drawn],
      flowStep: ReadingFlowStep.reveal,
      currentPositionIndex: current.drawnCards.length,
    );
    await _persist();
    notifyListeners();
    return drawn;
  }

  Future<void> advanceAfterReveal() async {
    final current = _session;
    if (current == null) return;

    if (current.allCardsDrawn) {
      await _updateStep(ReadingFlowStep.reading);
    } else {
      await _updateStep(ReadingFlowStep.cardSelection);
    }
  }

  Future<AiReadingContent> resolveInterpretationContent({
    JourneyPersonalizationHints? journeyHints,
  }) async {
    final current = _session;
    if (current == null) {
      throw StateError('No active reading session');
    }
    isLoading = true;
    notifyListeners();
    try {
      final content = await _interpretationService.generateContent(
        current,
        journeyHints: journeyHints,
      );
      _session = current.copyWith(
        interpretation: content.fullInterpretation,
        flowStep: ReadingFlowStep.reading,
      );
      await _persist();
      return content;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> generateInterpretation() async {
    final content = await resolveInterpretationContent();
    return content.fullInterpretation ?? content.generalMeaning;
  }

  Future<ReadingSession> completeSession() async {
    final current = _session;
    if (current == null) throw StateError('No active session');
    final completedAt = DateTime.now();
    final duration = completedAt.difference(current.startedAt);
    _session = current.copyWith(
      status: ReadingSessionStatus.completed,
      flowStep: ReadingFlowStep.completed,
      completedAt: completedAt,
      durationMs: duration.inMilliseconds,
    );
    await _repository.saveSession(_session!);
    await _repository.clearActiveSession();
    notifyListeners();
    return _session!;
  }

  Future<void> loadSession(String id) async {
    _session = await _repository.loadSession(id);
    if (_session != null) {
      _deckController.restorePile(
        deckId: _session!.deckId,
        seed: _session!.shuffleSeed,
        drawnCardIds: _session!.drawnCards.map((c) => c.card.id).toList(),
      );
    }
    notifyListeners();
  }

  Future<List<ReadingSession>> loadHistory() =>
      _repository.loadCompletedSessions();

  Future<void> updateSession(ReadingSession session) async {
    _session = session;
    await _persist();
    notifyListeners();
  }

  void resetSession() {
    _session = null;
    _deckController.resetPile();
    notifyListeners();
  }

  Future<void> _updateStep(ReadingFlowStep step) async {
    final current = _session;
    if (current == null) return;
    _session = current.copyWith(flowStep: step);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_session != null) {
      await _repository.saveSession(_session!);
    }
  }

  @override
  void dispose() {
    _deckController.dispose();
    super.dispose();
  }
}
