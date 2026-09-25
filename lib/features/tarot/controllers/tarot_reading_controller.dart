/// OR-1170 — Tarot reading session controller.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

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
import '../narrative/live/narrative_tarot_live_gate.dart';
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
  /// True when durable draw state could not be reconciled after a persist fault.
  bool _drawStateUncertain = false;
  /// Invalidates in-flight draw ownership on abandon/reset.
  int _lifecycleEpoch = 0;
  /// Completes when the current draw transaction finishes (success or fail).
  Future<void>? _activeDrawQuiesce;
  Future<AiReadingContent>? _interpretationInflight;
  int _sessionSeq = 0;

  ReadingSession? get session => _session;
  TarotDeckController get deckController => _deckController;
  bool get drawStateUncertain => _drawStateUncertain;

  bool _ownsEpoch(int epoch) => epoch == _lifecycleEpoch;

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

  /// Drop a prior in-progress session so a new ritual cannot collide with
  /// restore / daily-draw races on a stale active document.
  ///
  /// Invalidates draw ownership first, waits for any in-flight draw persist to
  /// quiesce, then clears durable active so a stale save cannot resurrect it.
  Future<void> abandonActiveForNewStart() async {
    _lifecycleEpoch++;
    final pending = _activeDrawQuiesce;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
    }
    await _repository.clearActiveSession();
    _session = null;
    _drawLocked = false;
    _drawStateUncertain = false;
    _interpretationInflight = null;
    clearError();
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
    var stage = 'abandon';
    try {
      await abandonActiveForNewStart();
      stage = 'initializeDeck';
      final seed = DateTime.now().millisecondsSinceEpoch;
      await _deckController.initializeDeck(deckId: deckId, seed: seed);
      if (_deckController.drawPile.isEmpty) {
        throw StateError('Tarot deck failed to initialize');
      }
      stage = 'createSession';
      _sessionSeq += 1;
      _session = ReadingSession(
        id: 'session_${seed}_$_sessionSeq',
        deckId: _deckController.deckId,
        userId: userId,
        spread: spread,
        intention: intention,
        shuffleSeed: seed,
        startedAt: DateTime.now(),
        flowStep: ReadingFlowStep.deckSelection,
      );
      stage = 'persist';
      await _persist();
      return _session!;
    } catch (error, stack) {
      errorMessage = ResilienceCopy.sessionInitFailed;
      debugPrint('[TarotReading] beginSession failed at $stage: $error\n$stack');
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
    if (_drawStateUncertain) {
      throw StateError('Draw persistence state uncertain');
    }
    if (_drawLocked) {
      throw StateError('Draw in progress');
    }
    if (current.allCardsDrawn) {
      throw StateError('All cards already drawn');
    }
    _drawLocked = true;
    final epoch = _lifecycleEpoch;
    final quiesce = Completer<void>();
    _activeDrawQuiesce = quiesce.future;
    var releaseLock = true;
    try {
      final snapshot = current;
      final snapshotIds =
          snapshot.drawnCards.map((c) => c.card.id).toList(growable: false);
      final draw = fanIndex == null
          ? _deckController.drawNext()
          : _deckController.drawFromFan(fanIndex);
      final drawn = _buildDrawnCard(snapshot, draw);
      final candidate = _sessionWithDrawn(snapshot, drawn);
      final committed = await _commitDrawCandidate(
        snapshot: snapshot,
        snapshotDrawnIds: snapshotIds,
        candidate: candidate,
        epoch: epoch,
      );
      if (!_ownsEpoch(epoch)) {
        throw StateError('draw_stale');
      }
      if (!committed) {
        throw StateError('persist_failed');
      }
      return drawn;
    } on StateError catch (e) {
      if (e.message == 'Draw persistence state uncertain' ||
          e.message == 'draw_stale') {
        // Uncertain: keep lock. Stale: abandon/reset owns lock cleanup.
        releaseLock = false;
      }
      rethrow;
    } finally {
      if (releaseLock && _ownsEpoch(epoch)) _drawLocked = false;
      if (!quiesce.isCompleted) quiesce.complete();
      if (identical(_activeDrawQuiesce, quiesce.future)) {
        _activeDrawQuiesce = null;
      }
    }
  }

  /// OR AÇSIN — take the remaining spread cards from the shuffled pile.
  Future<void> drawAllRemaining() async {
    final current = _session;
    if (current == null) {
      throw StateError('No active reading session');
    }
    if (_drawStateUncertain) {
      throw StateError('Draw persistence state uncertain');
    }
    if (_drawLocked) return;
    _drawLocked = true;
    final epoch = _lifecycleEpoch;
    final quiesce = Completer<void>();
    _activeDrawQuiesce = quiesce.future;
    var releaseLock = true;
    try {
      final snapshot = current;
      final snapshotIds =
          snapshot.drawnCards.map((c) => c.card.id).toList(growable: false);
      var working = snapshot;
      while (!working.allCardsDrawn) {
        final draw = _deckController.drawNext();
        final drawn = _buildDrawnCard(working, draw);
        working = _sessionWithDrawn(working, drawn);
      }
      final candidate = working.copyWith(
        flowStep: ReadingFlowStep.reveal,
        currentPositionIndex: 0,
      );
      final committed = await _commitDrawCandidate(
        snapshot: snapshot,
        snapshotDrawnIds: snapshotIds,
        candidate: candidate,
        epoch: epoch,
      );
      if (!_ownsEpoch(epoch)) {
        throw StateError('draw_stale');
      }
      if (!committed) {
        throw StateError('persist_failed');
      }
    } on StateError catch (e) {
      if (e.message == 'Draw persistence state uncertain' ||
          e.message == 'draw_stale') {
        releaseLock = false;
      }
      rethrow;
    } finally {
      if (releaseLock && _ownsEpoch(epoch)) _drawLocked = false;
      if (!quiesce.isCompleted) quiesce.complete();
      if (identical(_activeDrawQuiesce, quiesce.future)) {
        _activeDrawQuiesce = null;
      }
    }
  }

  /// Persist [candidate] then assign `_session` when lifecycle still owns [epoch].
  /// On save failure: restore local snapshot first, then durable read-back.
  Future<bool> _commitDrawCandidate({
    required ReadingSession snapshot,
    required List<int> snapshotDrawnIds,
    required ReadingSession candidate,
    required int epoch,
  }) async {
    try {
      await _repository.saveSession(candidate);
      if (!_ownsEpoch(epoch)) return false;
      _session = candidate;
      notifyListeners();
      return true;
    } catch (_) {
      // P1-A: local known-good before any durable probe.
      _restoreLocalSnapshot(snapshot, snapshotDrawnIds);
      if (!_ownsEpoch(epoch)) return false;

      ReadingSession? durable;
      try {
        durable = await _repository.loadActiveSession();
      } catch (_) {
        if (!_ownsEpoch(epoch)) return false;
        _drawStateUncertain = true;
        throw StateError('Draw persistence state uncertain');
      }
      if (!_ownsEpoch(epoch)) return false;

      if (_sameDrawCommit(durable, candidate)) {
        // WRITE-THEN-THROW: durable has candidate; re-apply locally.
        _restoreLocalCandidate(candidate);
        notifyListeners();
        return true;
      }

      // Fail-before-write / durable still pre-draw — already at snapshot.
      if (_needsDrawCompensation(durable, snapshot)) {
        if (!_ownsEpoch(epoch)) return false;
        try {
          await _repository.saveSession(snapshot);
        } catch (_) {
          if (!_ownsEpoch(epoch)) return false;
          _drawStateUncertain = true;
          throw StateError('Draw persistence state uncertain');
        }
        if (!_ownsEpoch(epoch)) return false;
      } else if (durable != null &&
          durable.id == snapshot.id &&
          !_sameDrawCommit(durable, snapshot)) {
        // Divergent durable that is neither snapshot nor candidate.
        _drawStateUncertain = true;
        throw StateError('Draw persistence state uncertain');
      }
      return false;
    }
  }

  void _restoreLocalSnapshot(
    ReadingSession snapshot,
    List<int> snapshotDrawnIds,
  ) {
    _session = snapshot;
    _deckController.restorePile(
      deckId: snapshot.deckId,
      seed: snapshot.shuffleSeed,
      drawnCardIds: snapshotDrawnIds,
    );
  }

  void _restoreLocalCandidate(ReadingSession candidate) {
    _session = candidate;
    _deckController.restorePile(
      deckId: candidate.deckId,
      seed: candidate.shuffleSeed,
      drawnCardIds:
          candidate.drawnCards.map((c) => c.card.id).toList(growable: false),
    );
  }

  static bool _sameDrawCommit(ReadingSession? durable, ReadingSession candidate) {
    if (durable == null || durable.id != candidate.id) return false;
    if (durable.drawnCards.length != candidate.drawnCards.length) return false;
    for (var i = 0; i < durable.drawnCards.length; i++) {
      if (durable.drawnCards[i].card.id != candidate.drawnCards[i].card.id) {
        return false;
      }
      if (durable.drawnCards[i].isReversed !=
          candidate.drawnCards[i].isReversed) {
        return false;
      }
    }
    return true;
  }

  static bool _needsDrawCompensation(
    ReadingSession? durable,
    ReadingSession snapshot,
  ) {
    if (durable == null || durable.id != snapshot.id) return false;
    if (durable.drawnCards.length == snapshot.drawnCards.length) return false;
    return true;
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

  TarotDrawnCard _buildDrawnCard(
    ReadingSession current,
    ({TarotCard card, bool isReversed}) draw,
  ) {
    final position = SpreadService.positionAt(
      current.spread,
      current.drawnCards.length,
    );
    return TarotDrawnCard(
      card: draw.card,
      positionIndex: current.drawnCards.length,
      isReversed: draw.isReversed,
      positionLabel: position?.label,
      positionKey: position?.key,
    );
  }

  ReadingSession _sessionWithDrawn(
    ReadingSession current,
    TarotDrawnCard drawn,
  ) {
    return current.copyWith(
      drawnCards: [...current.drawnCards, drawn],
      flowStep: ReadingFlowStep.reveal,
      currentPositionIndex: current.drawnCards.length,
    );
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
        // Safety copy is display-only — never store as completed interpretation.
        if (content.isJournalEligible) {
          final mode = NarrativeTarotLiveGate.shouldUseNarrative(current.spread)
              ? 'narrativeV2'
              : 'legacy';
          _session = current.copyWith(
            interpretation: content.fullInterpretation,
            interpretationResultMode: mode,
            interpretationSource: content.interpretationSource.name,
            interpretationDeliveryKind: content.deliveryKind.name,
            interpretationLocale: OraclyL10n.code,
            flowStep: ReadingFlowStep.reading,
          );
          await _persist();
        } else {
          _session = current.copyWith(flowStep: ReadingFlowStep.reading);
        }
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

  /// Local-only reset. Invalidates in-flight draw ownership; does not clear
  /// durable storage — use [abandonActiveForNewStart] for that.
  void resetSession() {
    _lifecycleEpoch++;
    _session = null;
    _deckController.resetPile();
    _drawLocked = false;
    _drawStateUncertain = false;
    _interpretationInflight = null;
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
    _lifecycleEpoch++;
    _drawLocked = false;
    _drawStateUncertain = false;
    _interpretationInflight = null;
    _deckController.dispose();
    super.dispose();
  }
}
