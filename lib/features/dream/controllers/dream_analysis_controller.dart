/// SPRINT-001 — Dream journey state machine.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/dream.dart';
import '../models/dream_emotion.dart';
import '../../../core/l10n/l10n.dart';
import '../models/dream_entry_selection.dart';
import '../safety/dream_safety_concern.dart';
import '../safety/dream_safety_presentation.dart';
import '../services/dream_experience_service.dart';
import '../services/dream_narrative_language.dart';
import '../services/dream_owner_guard.dart';
import 'dream_analysis_failure.dart';

enum DreamJourneyPhase {
  entry,
  organizing,
  reflecting,
  complete,
  error,

  /// Local safety guidance — not a reading, never saved or versioned.
  safety,
}

class DreamAnalysisController extends ChangeNotifier {
  DreamAnalysisController(
    this._service, {
    Duration organizingDelay = const Duration(milliseconds: 480),
  }) : _organizingDelay = organizingDelay;

  final DreamExperienceService _service;
  final Duration _organizingDelay;
  bool _disposed = false;
  int _generation = 0;

  DreamJourneyPhase _phase = DreamJourneyPhase.entry;
  Dream? _dream;
  String? _errorMessage;
  DreamSafetyPresentation? _safety;
  List<Dream> _history = const [];
  bool _versionAdded = false;
  int _versionReloadToken = 0;
  bool _reinterpretFailed = false;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  bool _stale(int token) => _disposed || token != _generation;

  bool get _busy =>
      _phase == DreamJourneyPhase.organizing ||
      _phase == DreamJourneyPhase.reflecting;

  DreamJourneyPhase get phase => _phase;
  Dream? get dream => _dream;
  String? get errorMessage => _errorMessage;
  DreamSafetyPresentation? get safety => _safety;
  List<Dream> get history => _history;
  bool get lastVersionAdded => _versionAdded;
  int get versionReloadToken => _versionReloadToken;

  /// The error came from reinterpreting [dream], which is still retained:
  /// retry reinterprets it again, back returns to it.
  bool get reinterpretFailed =>
      _reinterpretFailed && _phase == DreamJourneyPhase.error && _dream != null;

  @visibleForTesting
  void seedHistoryForTest(List<Dream> dreams) {
    _history = List<Dream>.unmodifiable(dreams);
    _safeNotify();
  }

  Future<void> loadHistory() => _loadHistoryFor(_generation);

  Future<void> _loadHistoryFor(int token) async {
    final history = await _service.loadHistory();
    if (_stale(token)) return;
    _history = history;
    _safeNotify();
  }

  Future<void> submit({
    required String narrative,
    List<DreamEmotion> emotions = const [],
    List<String> tags = const [],
    DreamEntrySelection? entry,
  }) async {
    if (_disposed || _busy) return;
    final token = ++_generation;
    _phase = DreamJourneyPhase.organizing;
    _errorMessage = null;
    _safety = null;
    _safeNotify();

    await Future<void>.delayed(_organizingDelay);
    if (_stale(token)) return;

    _phase = DreamJourneyPhase.reflecting;
    _safeNotify();

    try {
      final result = await _service.analyze(
        narrative: narrative,
        selectedEmotions: emotions,
        tags: tags,
        entry: entry,
      );
      if (_stale(token)) return;
      _dream = result.dream;
      _phase = DreamJourneyPhase.complete;
      await _loadHistoryFor(token);
    } catch (error) {
      if (_stale(token)) return;
      if (error is DreamOwnerChangedException) return _returnToEntry(token);
      if (error is DreamSafetyException) {
        _enterSafety(error.concern, narrative);
      } else {
        _fail('analyze', error);
      }
    }
    _safeNotify();
  }

  Future<void> reinterpret() async {
    if (_disposed || _busy) return;
    final current = _dream;
    if (current == null) {
      throw StateError('dream reinterpret failed');
    }
    final token = ++_generation;
    _phase = DreamJourneyPhase.reflecting;
    _errorMessage = null;
    _safeNotify();
    try {
      final result = await _service.reinterpret(current);
      if (_stale(token)) return;
      _versionAdded = result.versionAdded;
      if (result.versionAdded) {
        _dream = result.dream;
        _versionReloadToken++;
        await _loadHistoryFor(token);
        if (_stale(token)) return;
      }
      _phase = DreamJourneyPhase.complete;
    } catch (error) {
      if (_stale(token)) return;
      if (error is DreamOwnerChangedException) return _returnToEntry(token);
      if (error is DreamSafetyException) {
        _enterSafety(error.concern, current.narrative);
      } else {
        _fail('reinterpret', error);
      }
    }
    _safeNotify();
    if (!_stale(token) && _phase == DreamJourneyPhase.error) {
      throw StateError('dream reinterpret failed');
    }
  }

  /// Local safety guidance instead of a reading: nothing was attempted,
  /// charged, sent or stored for it.
  void presentSafety(DreamSafetyConcern concern, {required String narrative}) {
    if (_disposed || _busy) return;
    _generation++;
    _enterSafety(concern, narrative);
    _safeNotify();
  }

  void _enterSafety(DreamSafetyConcern concern, String narrative) {
    _safety = DreamSafetyPresentation(
      concern: concern,
      language: DreamNarrativeLanguage.forOperation(narrative, OraclyL10n.code),
    );
    _dream = null;
    _errorMessage = null;
    _versionAdded = false;
    _phase = DreamJourneyPhase.safety;
  }

  /// Shows the stored copy of [dream] only after it resolves in the current
  /// owner's storage. Until then nothing about it is visible; a stale object
  /// from a prior owner or a clear returns to entry instead.
  Future<void> openSaved(Dream dream) async {
    if (_disposed) return;
    final token = ++_generation;
    Dream? stored;
    try {
      stored = await _service.loadOwnedDream(dream.id);
    } catch (_) {}
    if (_stale(token)) return;
    if (stored == null) return _returnToEntry(token);
    _dream = stored;
    _errorMessage = null;
    _safety = null;
    _phase = DreamJourneyPhase.complete;
    _safeNotify();
  }

  Future<void> _returnToEntry(int token) async {
    _phase = DreamJourneyPhase.entry;
    _dream = null;
    _errorMessage = null;
    _safety = null;
    _history = const [];
    _safeNotify();
    await _loadHistoryFor(token);
  }

  void _fail(String stage, Object error) {
    _errorMessage = DreamAnalysisFailure.messageFor(stage, error);
    _reinterpretFailed = stage == 'reinterpret';
    _phase = DreamJourneyPhase.error;
  }

  /// Back from a failed reinterpret: the reading it started from, unchanged.
  void returnToReading() {
    if (_disposed || !reinterpretFailed) return;
    _generation++;
    _reinterpretFailed = false;
    _errorMessage = null;
    _phase = DreamJourneyPhase.complete;
    _safeNotify();
  }

  /// The screen was left. A finished session (result, error or safety) must
  /// not greet the next visit; an analysis still running is kept.
  void releaseSession() {
    if (_disposed || _busy || _phase == DreamJourneyPhase.entry) return;
    reset();
  }

  void reset() {
    if (_disposed) return;
    _generation++;
    _reinterpretFailed = false;
    _phase = DreamJourneyPhase.entry;
    _dream = null;
    _errorMessage = null;
    _safety = null;
    _safeNotify();
  }
}
