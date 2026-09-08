/// Birth chart journey state machine.
library;

import 'package:flutter/foundation.dart';

import '../copy/birth_chart_copy.dart';
import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import '../services/birth_chart_experience_service.dart';
import '../services/birth_chart_persistence_validator.dart';
import 'birth_chart_phase.dart';

export 'birth_chart_phase.dart';

class BirthChartController extends ChangeNotifier {
  BirthChartController(this._service);

  final BirthChartExperienceService _service;

  BirthChartPhase _phase = BirthChartPhase.onboarding;
  BirthChart? _chart;
  String? _errorMessage;
  BirthProfile? _lastProfile;
  BirthProfile? _onboardingProfileHint;
  String? _statusMessage;
  var _isInitializing = true;
  var _editing = false;
  var _disposed = false;

  BirthChartPhase get phase => _phase;
  BirthChart? get chart => _chart;
  String? get errorMessage => _errorMessage;
  BirthProfile? get onboardingProfileHint => _onboardingProfileHint;
  String? get statusMessage => _statusMessage;
  bool get isInitializing => _isInitializing;
  bool get isEditing => _editing;

  bool get hasRenderableJourney =>
      _chart != null && BirthChartPersistenceValidator.isJourneyReady(_chart!);

  Future<void> loadSaved() async {
    if (_phase == BirthChartPhase.generating) return;
    try {
      final result = await _service.loadSaved();
      if (_disposed || _phase == BirthChartPhase.generating) return;
      switch (result.status) {
        case BirthChartLoadStatus.none:
          break;
        case BirthChartLoadStatus.loaded:
          final chart = result.chart;
          if (chart != null) {
            _chart = chart;
            _lastProfile = chart.profile;
            _editing = false;
            _phase = BirthChartPhase.journey;
          }
        case BirthChartLoadStatus.clearedCorrupt:
          _applyOnboardingHint(result.profileHint);
          _statusMessage = BirthChartCopy.corruptDataCleared;
      }
    } catch (_) {
      if (_disposed) return;
      if (_phase != BirthChartPhase.generating) {
        await _service.clearSavedData();
        if (_disposed) return;
        _errorMessage = BirthChartCopy.recoverFailed;
        _phase = BirthChartPhase.error;
      }
    } finally {
      if (!_disposed) {
        _isInitializing = false;
        notifyListeners();
      }
    }
  }

  Future<void> generate(BirthProfile profile) async {
    if (_disposed) return;
    _lastProfile = profile;
    _onboardingProfileHint = profile;
    _statusMessage = null;
    _editing = false;
    _phase = BirthChartPhase.generating;
    _errorMessage = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (_disposed) return;
    try {
      final result = await _service.generate(profile);
      if (_disposed) return;
      if (!BirthChartPersistenceValidator.isJourneyReady(result.chart)) {
        throw StateError('Birth chart insights missing after generation');
      }
      _chart = result.chart;
      _phase = BirthChartPhase.journey;
    } catch (_) {
      if (_disposed) return;
      _phase = BirthChartPhase.error;
      _errorMessage = BirthChartCopy.generateFailed;
    }
    if (!_disposed) notifyListeners();
  }

  void beginEdit() {
    if (_disposed) return;
    _applyOnboardingHint(_chart?.profile ?? _lastProfile);
    _editing = true;
    _phase = BirthChartPhase.onboarding;
    _statusMessage = null;
    notifyListeners();
  }

  void cancelEdit() {
    if (_disposed) return;
    _editing = false;
    if (_chart != null &&
        BirthChartPersistenceValidator.isJourneyReady(_chart!)) {
      _phase = BirthChartPhase.journey;
    }
    notifyListeners();
  }

  Future<void> recoverJourney() async {
    if (_disposed) return;
    final profile = _chart?.profile ?? _lastProfile;
    if (profile == null) {
      await restartOnboarding();
      return;
    }
    await generate(profile);
  }

  Future<void> regenerateFromSavedProfile() async {
    if (_disposed) return;
    final profile = _chart?.profile ?? _lastProfile ?? _onboardingProfileHint;
    if (profile == null) {
      await restartOnboarding();
      return;
    }
    await generate(profile);
  }

  Future<void> clearSavedAndRestart({BirthProfile? profileHint}) async {
    if (_disposed) return;
    final hint =
        profileHint ?? _chart?.profile ?? _lastProfile ?? _onboardingProfileHint;
    await _service.clearSavedData();
    if (_disposed) return;
    _chart = null;
    _editing = false;
    _errorMessage = null;
    _phase = BirthChartPhase.onboarding;
    _applyOnboardingHint(hint);
    _statusMessage = BirthChartCopy.savedDataCleared;
    notifyListeners();
  }

  Future<void> restartOnboarding() => clearSavedAndRestart();

  void consumeStatusMessage() => _statusMessage = null;

  void _applyOnboardingHint(BirthProfile? profile) {
    if (profile != null) {
      _onboardingProfileHint = profile;
      _lastProfile = profile;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
