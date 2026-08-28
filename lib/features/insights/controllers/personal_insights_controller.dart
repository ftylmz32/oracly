/// SPRINT-004 — Personal Insights screen state machine.
library;

import 'package:flutter/foundation.dart';

import '../../../core/copy/resilience_copy.dart';
import '../../../core/security/ai_error_sanitizer.dart';
import '../models/reflection_summary.dart';
import '../services/personal_insights_experience_service.dart';

enum PersonalInsightsPhase { loading, ready, empty, error }

class PersonalInsightsState {
  const PersonalInsightsState({
    this.phase = PersonalInsightsPhase.loading,
    this.summary,
    this.error,
  });

  final PersonalInsightsPhase phase;
  final InsightReflectionSummary? summary;
  final String? error;

  PersonalInsightsState copyWith({
    PersonalInsightsPhase? phase,
    InsightReflectionSummary? summary,
    String? error,
  }) {
    return PersonalInsightsState(
      phase: phase ?? this.phase,
      summary: summary ?? this.summary,
      error: error,
    );
  }
}

class PersonalInsightsController extends ChangeNotifier {
  PersonalInsightsController(this._service);

  final PersonalInsightsExperienceService _service;

  PersonalInsightsState _state = const PersonalInsightsState();
  PersonalInsightsState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(phase: PersonalInsightsPhase.loading, error: null);
    notifyListeners();

    try {
      final raw = await _service.generate();
      final filtered = await _service.applyPrivacyFilters(raw);
      final phase = filtered.hasContent
          ? PersonalInsightsPhase.ready
          : PersonalInsightsPhase.empty;
      _state = _state.copyWith(phase: phase, summary: filtered);
    } catch (e) {
      _state = _state.copyWith(
        phase: PersonalInsightsPhase.error,
        error: AiErrorSanitizer.publicMessage(
          error: e,
          fallback: ResilienceCopy.genericLoadFailed,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> regenerate() => load();

  Future<void> hideInsight(String id) async {
    await _service.hideInsight(id);
    await load();
  }

  Future<void> deleteInsight(String id) async {
    await _service.deleteInsight(id);
    await load();
  }

  String exportText() {
    final summary = _state.summary;
    if (summary == null) return '';
    return _service.exportAsText(summary);
  }
}
