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

  int _ticket = 0;
  bool _disposed = false;

  bool _current(int ticket) => !_disposed && ticket == _ticket;

  void _publish(PersonalInsightsState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  Future<void> load() async {
    final ticket = ++_ticket;
    _publish(const PersonalInsightsState());

    try {
      final raw = await _service.generate();
      if (!_current(ticket)) return;
      final filtered = await _service.applyPrivacyFilters(raw);
      if (!_current(ticket)) return;
      final phase = filtered.hasContent
          ? PersonalInsightsPhase.ready
          : PersonalInsightsPhase.empty;
      _publish(PersonalInsightsState(phase: phase, summary: filtered));
    } catch (e) {
      if (!_current(ticket)) return;
      _publish(
        PersonalInsightsState(
          phase: PersonalInsightsPhase.error,
          error: AiErrorSanitizer.publicMessage(
            error: e,
            fallback: ResilienceCopy.genericLoadFailed,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticket++;
    super.dispose();
  }

  Future<void> regenerate() => load();

  Future<bool> hideInsight(String id) async {
    final saved = await _service.hideInsight(id);
    if (!saved) return false;
    await load();
    return _state.phase != PersonalInsightsPhase.error;
  }

  Future<bool> deleteInsight(String id) async {
    final saved = await _service.deleteInsight(id);
    if (!saved) return false;
    await load();
    return _state.phase != PersonalInsightsPhase.error;
  }

  String exportText() {
    final summary = _state.summary;
    if (summary == null) return '';
    return _service.exportAsText(summary);
  }
}
