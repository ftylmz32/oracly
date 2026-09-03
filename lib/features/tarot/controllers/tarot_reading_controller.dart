/// OR-1170 — Tarot reading session controller.
library;

import '../../../core/copy/resilience_copy.dart';
import '../../../core/l10n/l10n.dart';
import '../domain/models/reading_session.dart';
import '../domain/models/reading_session_draw.dart';
import '../domain/models/tarot_session_recovery.dart';
import '../models/tarot_card.dart';
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
  }) : _repository =
           repository ??
           (throw ArgumentError('TarotReadingRepository is required')),
       _deckController = deckController ?? TarotDeckController(),
       _interpretationService =
           interpretationService ?? TarotInterpretationService();

  final TarotReadingRepository _repository;
  final TarotDeckController _deckController;
  final TarotInterpretationService _interpretationService;

  ReadingSession? _session;
  bool _drawLocked = false;
  Future<AiReadingContent>? _interpretationInflight;

  ReadingSession? get session => _session;
  TarotDeckController get deckController => _deckController;

  Future<void> restoreActiveSession() async {
    final raw = await _repository.loadActiveSession();
    final recovered = TarotSessionRecovery.prepare(raw, activeOnly: true);
    if (recovered == null) {
      await _repository.clearActiveSession();
      return;
    }
    _session = recovered;
    _deckController.restorePile(
      deckId: recovered.deckId,
      seed: recovered.shuffleSeed,
      drawnCardIds: recovered.drawnCards.map((c) => c.card.id).toList(),
    );
    final changed =
        raw != null &&
        (raw.flowStep != recovered.flowStep ||
            raw.drawnCards.length != recovered.drawnCards.length);
    if (changed) await _persist();
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
    notifyListeners();
  }

  Future<void> finishShuffle() async {
    await _updateStep(ReadingFlowStep.cardSelection);
  }

  Future<TarotDrawnCard> drawCard({int? fanIndex}) async {
    final current = _session;
    if (current == null) {
      throw StateError('No active reading session');
    }
    if (_drawLocked) {
      throw StateError('Draw in progress');
    }
    if (current.allCardsDrawn) {
      throw StateError('All cards already drawn');
    }
    _drawLocked = true;
    try {
      final draw = fanIndex == null
          ? _deckController.drawNext()
          : _deckController.drawFromFan(fanIndex);
      final drawn = _applyDraw(current, draw);
      await _persist();
      notifyListeners();
      return drawn;
    } finally {
      _drawLocked = false;
    }
  }

  /// OR AÇSIN — take the remaining spread cards from the shuffled pile.
  Future<void> drawAllRemaining() async {
    var current = _session;
    if (current == null) {
      throw StateError('No active reading session');
    }
    if (_drawLocked) return;
    _drawLocked = true;
    try {
      while (!current!.allCardsDrawn) {
        _applyDraw(current, _deckController.drawNext());
        current = _session!;
      }
      _session = current.copyWith(
        flowStep: ReadingFlowStep.reveal,
        currentPositionIndex: 0,
      );
      await _persist();
      notifyListeners();
    } finally {
      _drawLocked = false;
    }
  }

  Future<void> advanceAfterReveal() async {
    final current = _session;
    if (current == null) return;
    // Snapshot so a failed persist never leaves a half-advanced session;
    // retry must rerun only this stage with unchanged cards/identity.
    final snapshot = current;
    try {
      if (current.hasQueuedReveal) {
        _session = current.copyWith(
          flowStep: ReadingFlowStep.reveal,
          currentPositionIndex: current.currentPositionIndex + 1,
        );
        await _persist();
        notifyListeners();
        return;
      }

      if (current.allCardsDrawn) {
        await _updateStep(ReadingFlowStep.reading);
      } else {
        await _updateStep(ReadingFlowStep.cardSelection);
      }
    } catch (_) {
      _session = snapshot;
      notifyListeners();
      rethrow;
    }
  }

  TarotDrawnCard _applyDraw(
    ReadingSession current,
    ({TarotCard card, bool isReversed}) draw,
  ) {
    final position = SpreadService.positionAt(
      current.spread,
      current.drawnCards.length,
    );
    final drawn = TarotDrawnCard(
      card: draw.card,
      positionIndex: current.drawnCards.length,
      isReversed: draw.isReversed,
      positionLabel: position?.label,
      positionKey: position?.key,
    );

    _session = current.copyWith(
      drawnCards: [...current.drawnCards, drawn],
      flowStep: ReadingFlowStep.reveal,
      currentPositionIndex: current.drawnCards.length,
    );
    return drawn;
  }

  Future<AiReadingContent> resolveInterpretationContent({
    JourneyPersonalizationHints? journeyHints,
    bool forceRefresh = false,
  }) async {
    final current = _session;
    if (current == null) {
      throw StateError('No active reading session');
    }
    final pending = _interpretationInflight;
    if (pending != null) return pending;
    isLoading = true;
    notifyListeners();
    final future = () async {
      try {
        final content = await _interpretationService.generateContent(
          current,
          language: OraclyL10n.code,
          journeyHints: journeyHints,
          forceRefresh: forceRefresh,
        );
        if (_session?.id != current.id) {
          throw StateError('Reading session changed');
        }
        _session = current.copyWith(
          interpretation: content.fullInterpretation,
          flowStep: ReadingFlowStep.reading,
        );
        await _persist();
        return content;
      } finally {
        isLoading = false;
        _interpretationInflight = null;
        notifyListeners();
      }
    }();
    _interpretationInflight = future;
    return future;
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

  Future<void> flush() => _persist();

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
