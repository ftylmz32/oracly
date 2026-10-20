/// Turns onboarding birth answers into the same profile Birth Chart builds.
library;

import 'package:flutter/material.dart';

import '../../birth_chart/data/birth_chart_cities.dart';
import '../../birth_chart/models/birth_profile.dart';
import '../../birth_chart/presentation/widgets/birth_chart_onboarding_actions.dart';

abstract final class OnboardingBirthProfile {
  OnboardingBirthProfile._();

  /// A picked catalogue city keeps its coordinates and timezone, so the
  /// saved chart reaches the same fidelity as the Birth Chart form.
  /// No city stays an open question (not a confirmed unknown), so
  /// Yıldızname can ask for it later instead of storing a fake place.
  static BirthProfile build({
    required DateTime birthDate,
    String? birthPlace,
    DateTime? birthTime,
    bool birthTimeKnown = false,
  }) {
    final known = birthTimeKnown && birthTime != null;
    final city = BirthChartCities.byName(birthPlace);
    if (city == null) {
      return BirthProfile(
        birthDate: birthDate,
        birthPlace: '',
        birthTime: known
            ? DateTime(
                birthDate.year,
                birthDate.month,
                birthDate.day,
                birthTime.hour,
                birthTime.minute,
              )
            : null,
        birthTimeKnown: known,
      );
    }
    return BirthChartOnboardingActions.buildProfile(
      date: birthDate,
      timeKnown: known,
      time: known ? TimeOfDay.fromDateTime(birthTime) : null,
      city: city,
    );
  }
}
