/// SPRINT-001 — Dream journey state machine.
library;

import 'package:flutter/foundation.dart';

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
  DreamAnalysisController(this._service);

  final DreamExperienceService _service;

  DreamJourneyPhase _phase = DreamJourneyPhase.entry;
  Dream? _dream;
  String? _errorMessage;
  List<Dream> _history = const [];

  DreamJourneyPhase get phase => _phase;
  Dream? get dream => _dream;
  String? get errorMessage => _errorMessage;
  List<Dream> get history => _history;

  Future<void> loadHistory() async {
    _history = await _service.loadHistory();
    notifyListeners();
  }

  Future<void> submit({
    required String narrative,
    List<DreamEmotion> emotions = const [],
    List<String> tags = const [],
  }) async {
    _phase = DreamJourneyPhase.organizing;
    _errorMessage = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 480));

    _phase = DreamJourneyPhase.reflecting;
    notifyListeners();

    try {
      final result = await _service.analyze(
        narrative: narrative,
        selectedEmotions: emotions,
        tags: tags,
      );
      _dream = result.dream;
      _phase = DreamJourneyPhase.complete;
      await loadHistory();
    } catch (e) {
      _phase = DreamJourneyPhase.error;
      _errorMessage = 'Rüya analizi tamamlanamadı. Biraz sonra tekrar dene.';
    }
    notifyListeners();
  }

  void reset() {
    _phase = DreamJourneyPhase.entry;
    _dream = null;
    _errorMessage = null;
    notifyListeners();
  }
}
