/// SPRINT-001 — Dream journey state machine.
library;

import 'package:flutter/foundation.dart';

import '../../../core/logging/analysis_debug_log.dart';
import '../../ai/production/ai_request_exception.dart';
import '../copy/dream_copy.dart';
import '../models/dream.dart';
import '../models/dream_emotion.dart';
import '../services/dream_experience_service.dart';

enum DreamJourneyPhase {
  entry,
  organizing,
  reflecting,
  complete,
  error,
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
  List<Dream> _history = const [];
  bool _versionAdded = false;
  int _versionReloadToken = 0;

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

  DreamJourneyPhase get phase => _phase;
  Dream? get dream => _dream;
  String? get errorMessage => _errorMessage;
  List<Dream> get history => _history;
  bool get lastVersionAdded => _versionAdded;
  int get versionReloadToken => _versionReloadToken;

  @visibleForTesting
  void seedHistoryForTest(List<Dream> dreams) {
    _history = List<Dream>.unmodifiable(dreams);
    _safeNotify();
  }

  Future<void> loadHistory() async {
    final token = _generation;
    final history = await _service.loadHistory();
    if (_disposed || token != _generation) return;
    _history = history;
    _safeNotify();
  }

  Future<void> _loadHistoryFor(int token) async {
    final history = await _service.loadHistory();
    if (_disposed || token != _generation) return;
    _history = history;
    _safeNotify();
  }

  Future<void> submit({
    required String narrative,
    List<DreamEmotion> emotions = const [],
    List<String> tags = const [],
  }) async {
    if (_disposed ||
        _phase == DreamJourneyPhase.organizing ||
        _phase == DreamJourneyPhase.reflecting) {
      return;
    }
    final token = ++_generation;
    _phase = DreamJourneyPhase.organizing;
    _errorMessage = null;
    _safeNotify();

    await Future<void>.delayed(_organizingDelay);
    if (_disposed || token != _generation) return;

    _phase = DreamJourneyPhase.reflecting;
    _safeNotify();

    try {
      final result = await _service.analyze(
        narrative: narrative,
        selectedEmotions: emotions,
        tags: tags,
      );
      if (_disposed || token != _generation) return;
      _dream = result.dream;
      _phase = DreamJourneyPhase.complete;
      await _loadHistoryFor(token);
    } on AiRequestException catch (e) {
      if (_disposed || token != _generation) return;
      logAnalysisFailure(
        feature: 'DreamAnalysis',
        stage: 'analyze',
        kind: e.failure.kind.name,
      );
      _phase = DreamJourneyPhase.error;
      _errorMessage = e.userMessage;
    } catch (error) {
      if (_disposed || token != _generation) return;
      logAnalysisFailure(
        feature: 'DreamAnalysis',
        stage: 'analyze',
        error: error,
      );
      _phase = DreamJourneyPhase.error;
      _errorMessage = DreamCopy.analysisFailed;
    }
    _safeNotify();
  }

  Future<void> reinterpret() async {
    if (_disposed ||
        _phase == DreamJourneyPhase.organizing ||
        _phase == DreamJourneyPhase.reflecting) {
      return;
    }
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
      if (_disposed || token != _generation) return;
      _versionAdded = result.versionAdded;
      if (result.versionAdded) {
        _dream = result.dream;
        _versionReloadToken++;
        await _loadHistoryFor(token);
        if (_disposed || token != _generation) return;
      }
      _phase = DreamJourneyPhase.complete;
    } on AiRequestException catch (e) {
      if (_disposed || token != _generation) return;
      logAnalysisFailure(
        feature: 'DreamAnalysis',
        stage: 'reinterpret',
        kind: e.failure.kind.name,
      );
      _phase = DreamJourneyPhase.error;
      _errorMessage = e.userMessage;
    } catch (error) {
      if (_disposed || token != _generation) return;
      logAnalysisFailure(
        feature: 'DreamAnalysis',
        stage: 'reinterpret',
        error: error,
      );
      _phase = DreamJourneyPhase.error;
      _errorMessage = DreamCopy.analysisFailed;
    }
    _safeNotify();
    if (!_disposed &&
        token == _generation &&
        _phase != DreamJourneyPhase.complete) {
      throw StateError('dream reinterpret failed');
    }
  }

  void openSaved(Dream dream) {
    if (_disposed) return;
    _generation++;
    _dream = dream;
    _errorMessage = null;
    _phase = DreamJourneyPhase.complete;
    _safeNotify();
  }

  void reset() {
    if (_disposed) return;
    _generation++;
    _phase = DreamJourneyPhase.entry;
    _dream = null;
    _errorMessage = null;
    _safeNotify();
  }
}
