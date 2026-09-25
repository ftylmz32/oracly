/// Onboarding buildProfile place/time/skip; known↔unknown clears.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_cities.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence_classifier.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence_completeness.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';
import 'package:oracly_new/features/birth_chart/presentation/widgets/birth_chart_onboarding_actions.dart';

void main() {
  final d = DateTime(1990, 3, 25);
  final city = BirthChartCities.byId('ankara')!;

  test('buildProfile place skip marks unknown and clears coords', () {
    final p = BirthChartOnboardingActions.buildProfile(
      date: d,
      timeKnown: false,
      time: const TimeOfDay(hour: 9, minute: 15),
      city: city,
      placeUnknown: true,
    );
    expect(p.birthPlaceUnknownConfirmed, isTrue);
    expect(p.birthPlace, isEmpty);
    expect(p.latitude, isNull);
    expect(p.longitude, isNull);
    expect(p.timezoneId, isNull);
    expect(p.birthTime, isNull);
    expect(
      BirthEvidenceClassifier.classify(BirthEvidence.fromProfile(p)),
      BirthEvidenceCompleteness.dateOnly,
    );
  });

  test('buildProfile city stamps resolved timezone + E2/E4', () {
    final e2 = BirthChartOnboardingActions.buildProfile(
      date: d,
      timeKnown: false,
      time: null,
      city: city,
    );
    expect(e2.timezoneId, 'Europe/Istanbul');
    expect(e2.timezoneResolutionStatus, BirthTimezoneStatus.resolved);
    expect(e2.birthPlaceUnknownConfirmed, isFalse);
    expect(
      BirthEvidenceClassifier.classify(BirthEvidence.fromProfile(e2)),
      BirthEvidenceCompleteness.dateAndPlaceNoTime,
    );

    final e4 = BirthChartOnboardingActions.buildProfile(
      date: d,
      timeKnown: true,
      time: const TimeOfDay(hour: 14, minute: 30),
      city: city,
    );
    expect(e4.hasKnownTime, isTrue);
    expect(
      BirthEvidenceClassifier.classify(BirthEvidence.fromProfile(e4)),
      BirthEvidenceCompleteness.full,
    );
  });

  test('known↔unknown time clears stale clock; place null skips', () {
    final unknownTime = BirthChartOnboardingActions.buildProfile(
      date: d,
      timeKnown: false,
      time: const TimeOfDay(hour: 12, minute: 0),
      city: null,
    );
    expect(unknownTime.birthTime, isNull);
    expect(unknownTime.birthTimeKnown, isFalse);
    expect(unknownTime.birthPlaceUnknownConfirmed, isTrue);

    final knownNoPlace = BirthChartOnboardingActions.buildProfile(
      date: d,
      timeKnown: true,
      time: const TimeOfDay(hour: 9, minute: 15),
      city: null,
    );
    expect(knownNoPlace.hasKnownTime, isTrue);
    expect(knownNoPlace.birthPlaceUnknownConfirmed, isTrue);
    expect(
      BirthEvidenceClassifier.classify(BirthEvidence.fromProfile(knownNoPlace)),
      BirthEvidenceCompleteness.dateAndTimeNoPlace,
    );
  });
}
