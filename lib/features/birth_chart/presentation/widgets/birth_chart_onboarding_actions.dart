/// Validation and profile assembly for Yildizname birth onboarding.
library;

import 'package:flutter/material.dart';

import '../../copy/birth_chart_copy.dart';
import '../../data/birth_chart_cities.dart';
import '../../models/birth_profile.dart';

abstract final class BirthChartOnboardingActions {
  BirthChartOnboardingActions._();

  static String? validate({
    required DateTime? date,
    required bool? timeKnown,
    required TimeOfDay? time,
  }) {
    if (date == null) return BirthChartCopy.birthDateRequired;
    if (timeKnown == null) return BirthChartCopy.timeChoiceRequired;
    if (timeKnown && time == null) return BirthChartCopy.birthTimeRequired;
    return null;
  }

  static String reviewTimeLabel({required bool? timeKnown, TimeOfDay? time}) {
    if (timeKnown == false) return BirthChartCopy.timeUnknownValue;
    if (timeKnown == true && time != null) {
      return '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}';
    }
    return BirthChartCopy.selectValue;
  }

  static BirthProfile buildProfile({
    required DateTime date,
    required bool timeKnown,
    required TimeOfDay? time,
    required BirthChartCity? city,
  }) {
    return BirthProfile(
      birthDate: date,
      birthPlace: city?.nameTr ?? '',
      birthTime: timeKnown && time != null
          ? DateTime(date.year, date.month, date.day, time.hour, time.minute)
          : null,
      birthTimeKnown: timeKnown,
      latitude: city?.latitude,
      longitude: city?.longitude,
    );
  }
}