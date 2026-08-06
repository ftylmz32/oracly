/// SPRINT-002 — Birth chart journey state machine.
library;

import 'package:flutter/foundation.dart';

import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import '../models/chart_insight.dart';
import '../services/birth_chart_experience_service.dart';

enum BirthChartPhase {
  onboarding,
  generating,
  journey,
  complete,
  error,
}

class BirthChartController extends ChangeNotifier {
  BirthChartController(this._service);

  final BirthChartExperienceService _service;

  BirthChartPhase _phase = BirthChartPhase.onboarding;
  BirthChart? _chart;
  int _stepIndex = 0;
  String? _errorMessage;

  BirthChartPhase get phase => _phase;
  BirthChart? get chart => _chart;
  int get stepIndex => _stepIndex;
  String? get errorMessage => _errorMessage;

  static const insightOrder = ChartInsightKind.values;

  ChartInsight? get currentInsight {
    final insights = _chart?.insights;
    if (insights == null || _stepIndex >= insights.length) return null;
    return insights[_stepIndex];
  }

  bool get isLastStep =>
      _chart != null && _stepIndex >= _chart!.insights.length - 1;

  Future<void> loadSaved() async {
    _chart = await _service.loadSaved();
    if (_chart != null) {
      _phase = BirthChartPhase.journey;
      _stepIndex = 0;
      notifyListeners();
    }
  }

  Future<void> generate(BirthProfile profile) async {
    _phase = BirthChartPhase.generating;
    _errorMessage = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 520));

    try {
      final result = await _service.generate(profile);
      _chart = result.chart;
      _stepIndex = 0;
      _phase = BirthChartPhase.journey;
    } catch (_) {
      _phase = BirthChartPhase.error;
      _errorMessage =
          'Harita oluşturulamadı. Biraz sonra tekrar deneyebilirsin.';
    }
    notifyListeners();
  }

  void nextStep() {
    if (_chart == null) return;
    if (_stepIndex < _chart!.insights.length - 1) {
      _stepIndex++;
      notifyListeners();
    } else {
      _phase = BirthChartPhase.complete;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_stepIndex > 0) {
      _stepIndex--;
      notifyListeners();
    }
  }

  void reset() {
    _phase = BirthChartPhase.onboarding;
    _chart = null;
    _stepIndex = 0;
    _errorMessage = null;
    notifyListeners();
  }
}
