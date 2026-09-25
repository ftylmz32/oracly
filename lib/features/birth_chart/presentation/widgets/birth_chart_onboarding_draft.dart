/// Mutable draft fields for birth onboarding form.
library;

import 'package:flutter/material.dart';

import '../../copy/birth_chart_copy.dart';
import '../../data/birth_chart_cities.dart';
import '../../models/birth_profile.dart';
import 'birth_chart_onboarding_actions.dart';

class BirthChartOnboardingDraft {
  DateTime? date;
  TimeOfDay? time;
  BirthChartCity? city;
  bool? timeKnown;
  var placeUnknown = false;

  void apply(BirthProfile? p) {
    if (p == null) return;
    date = p.birthDate;
    timeKnown = p.birthTimeKnown;
    time = p.hasKnownTime ? TimeOfDay.fromDateTime(p.birthTime!) : null;
    placeUnknown = p.birthPlaceUnknownConfirmed;
    city = placeUnknown
        ? null
        : BirthChartCities.byId(p.birthPlaceId) ??
            BirthChartCities.byName(p.birthPlace);
  }

  void skipPlace() {
    placeUnknown = true;
    city = null;
  }

  void setCity(BirthChartCity city) {
    this.city = city;
    placeUnknown = false;
  }

  void setTimeKnown(bool known) {
    timeKnown = known;
    if (!known) time = null;
  }

  String? validate() => BirthChartOnboardingActions.validate(
        date: date,
        timeKnown: timeKnown,
        time: time,
      );

  BirthProfile buildProfile() => BirthChartOnboardingActions.buildProfile(
        date: date!,
        timeKnown: timeKnown!,
        time: time,
        city: city,
        placeUnknown: placeUnknown,
      );

  String placeLabel() => placeUnknown
      ? BirthChartCopy.placeUnknownValue
      : (city?.label() ?? BirthChartCopy.birthPlaceHint);

  String? timeNote() => switch (timeKnown) {
        false => BirthChartCopy.timeUnknownNote,
        true => BirthChartCopy.timeImportance,
        null => null,
      };

  String timeLabel(BuildContext context) => timeKnown == false
      ? BirthChartCopy.timeUnknownValue
      : (time?.format(context) ?? BirthChartCopy.selectValue);
}
