/// Birth chart journey state machine.
library;

import 'package:flutter/foundation.dart';

import '../../../core/data/repositories/local_birth_chart_repository.dart';
import '../copy/birth_chart_copy.dart';
import '../evidence/birth_evidence.dart';
import '../evidence/birth_evidence_classifier.dart';
import '../evidence/birth_evidence_completeness.dart';
import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import '../services/birth_chart_experience_service.dart';
import '../services/birth_chart_persistence_validator.dart';
import 'birth_chart_phase.dart';
import 'birth_chart_session.dart';

export 'birth_chart_phase.dart';

class BirthChartController extends ChangeNotifier {
  BirthChartController(this._service);

  final BirthChartExperienceService _service;
  final _s = BirthChartSession();

  BirthChartPhase get phase => _s.phase;
  BirthChart? get chart => _s.chart;
  String? get errorMessage => _s.errorMessage;
  BirthProfile? get onboardingProfileHint => _s.onboardingProfileHint;
  String? get statusMessage => _s.statusMessage;
  bool get isInitializing => _s.isInitializing;
  bool get isEditing => _s.editing;
  bool get hasRenderableJourney => _s.hasRenderableJourney;

  BirthEvidenceCompleteness? get evidenceCompleteness {
    final p = _s.activeProfile;
    if (p == null) return null;
    return BirthEvidenceClassifier.classify(BirthEvidence.fromProfile(p));
  }

  Future<void> loadSaved() async {
    if (_s.phase == BirthChartPhase.generating) return;
    try {
      final result = await _service.loadSaved();
      if (_s.phase != BirthChartPhase.generating) _s.applyLoadResult(result);
    } on BirthChartOwnerUnavailableException {
      _s.markOwnerUnavailable();
    } catch (_) {
      await _clearOrOwnerGuard();
    } finally {
      _s.isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> generate(BirthProfile profile) async {
    _s.lastProfile = profile;
    _s.onboardingProfileHint = profile;
    _s.statusMessage = null;
    _s.editing = false;
    _s.phase = BirthChartPhase.generating;
    _s.errorMessage = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 420));
    try {
      final result = await _service.generate(profile);
      if (!BirthChartPersistenceValidator.isJourneyReady(result.chart)) {
        throw StateError('Birth chart insights missing after generation');
      }
      _s.chart = result.chart;
      _s.phase = BirthChartPhase.journey;
    } on BirthChartOwnerUnavailableException {
      _s.markOwnerUnavailable();
    } catch (_) {
      _s.phase = BirthChartPhase.error;
      _s.errorMessage = BirthChartCopy.generateFailed;
    }
    notifyListeners();
  }

  void beginEdit() {
    _s.applyOnboardingHint(_s.chart?.profile ?? _s.lastProfile);
    _s.editing = true;
    _s.phase = BirthChartPhase.onboarding;
    _s.statusMessage = null;
    notifyListeners();
  }

  void cancelEdit() {
    _s.editing = false;
    if (_s.chart != null &&
        BirthChartPersistenceValidator.isJourneyReady(_s.chart!)) {
      _s.phase = BirthChartPhase.journey;
    }
    notifyListeners();
  }

  Future<void> recoverJourney() async {
    final profile = _s.chart?.profile ?? _s.lastProfile;
    if (profile == null) {
      await restartOnboarding();
    } else {
      await generate(profile);
    }
  }

  Future<void> regenerateFromSavedProfile() async {
    final profile = _s.activeProfile;
    if (profile == null) {
      await restartOnboarding();
    } else {
      await generate(profile);
    }
  }

  Future<void> clearSavedAndRestart({BirthProfile? profileHint}) async {
    final hint = profileHint ?? _s.activeProfile;
    try {
      await _service.clearSavedData();
    } on BirthChartOwnerUnavailableException {
      _s.markOwnerUnavailable();
      notifyListeners();
      return;
    }
    _s.resetOnboarding(hint: hint, status: BirthChartCopy.savedDataCleared);
    notifyListeners();
  }

  Future<void> restartOnboarding() => clearSavedAndRestart();
  void consumeStatusMessage() => _s.statusMessage = null;

  Future<void> _clearOrOwnerGuard() async {
    if (_s.phase == BirthChartPhase.generating) return;
    try {
      await _service.clearSavedData();
    } on BirthChartOwnerUnavailableException {
      _s.markOwnerUnavailable();
      return;
    }
    _s.errorMessage = BirthChartCopy.recoverFailed;
    _s.phase = BirthChartPhase.error;
  }
}
