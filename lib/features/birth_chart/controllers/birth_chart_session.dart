/// Mutable journey session state for [BirthChartController].
library;

import '../copy/birth_chart_copy.dart';
import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import '../services/birth_chart_experience_service.dart';
import '../services/birth_chart_persistence_validator.dart';
import 'birth_chart_phase.dart';

class BirthChartSession {
  BirthChartPhase phase = BirthChartPhase.onboarding;
  BirthChart? chart;
  String? errorMessage;
  BirthProfile? lastProfile;
  BirthProfile? onboardingProfileHint;
  String? statusMessage;
  var isInitializing = true;
  var editing = false;

  bool get hasRenderableJourney =>
      chart != null && BirthChartPersistenceValidator.isJourneyReady(chart!);

  BirthProfile? get activeProfile =>
      chart?.profile ?? lastProfile ?? onboardingProfileHint;

  void applyOnboardingHint(BirthProfile? profile) {
    if (profile != null) {
      onboardingProfileHint = profile;
      lastProfile = profile;
    }
  }

  void markOwnerUnavailable() {
    chart = null;
    statusMessage = BirthChartCopy.ownerUnavailable;
    phase = BirthChartPhase.onboarding;
  }

  void applyLoadResult(BirthChartLoadResult result) {
    switch (result.status) {
      case BirthChartLoadStatus.none:
        break;
      case BirthChartLoadStatus.loaded:
        final loaded = result.chart;
        if (loaded != null) {
          chart = loaded;
          lastProfile = loaded.profile;
          editing = false;
          phase = BirthChartPhase.journey;
        }
      case BirthChartLoadStatus.clearedCorrupt:
        applyOnboardingHint(result.profileHint);
        statusMessage = BirthChartCopy.corruptDataCleared;
      case BirthChartLoadStatus.ownerUnavailable:
        markOwnerUnavailable();
    }
  }

  void resetOnboarding({BirthProfile? hint, required String status}) {
    chart = null;
    editing = false;
    errorMessage = null;
    phase = BirthChartPhase.onboarding;
    applyOnboardingHint(hint);
    statusMessage = status;
  }
}
