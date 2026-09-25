/// Task 49 old JSON; Tasks 60–61 stale clear via fromJson.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence_classifier.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence_completeness.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';

void main() {
  test('Task 49 legacy profile JSON survives without fabricating TZ/place', () {
    final p = BirthProfile.fromJson({
      'birthDate': '1990-03-25T00:00:00.000',
      'birthPlace': 'Ankara',
      'birthTimeKnown': false,
    });
    expect(p.birthPlace, 'Ankara');
    expect(p.timezoneId, isNull);
    expect(p.latitude, isNull);
    expect(p.longitude, isNull);
    expect(p.birthPlaceId, isNull);
    expect(p.timezoneResolutionStatus, BirthTimezoneStatus.missing);
    expect(p.birthPlaceUnknownConfirmed, isFalse);
    expect(
      BirthEvidenceClassifier.classify(BirthEvidence.fromProfile(p)),
      BirthEvidenceCompleteness.dateOnly,
    );
  });

  test('Task 61 fromJson clears stale time when time unknown', () {
    final p = BirthProfile.fromJson({
      'birthDate': '1990-03-25T00:00:00.000',
      'birthPlace': 'Ankara',
      'birthTimeKnown': false,
      'birthTime': '1990-03-25T12:00:00.000',
    });
    expect(p.birthTimeKnown, isFalse);
    expect(p.birthTime, isNull);
    expect(p.hasKnownTime, isFalse);
  });

  test('Task 60 fromJson clears stale place metadata when place unknown', () {
    final p = BirthProfile.fromJson({
      'birthDate': '1990-03-25T00:00:00.000',
      'birthPlace': 'Ankara',
      'birthTimeKnown': true,
      'birthTime': '1990-03-25T09:15:00.000',
      'birthPlaceUnknownConfirmed': true,
      'birthPlaceId': 'ankara',
      'latitude': 39.93,
      'longitude': 32.85,
      'timezoneId': 'Europe/Istanbul',
      'timezoneResolutionStatus': 'resolved',
    });
    expect(p.birthPlaceUnknownConfirmed, isTrue);
    expect(p.birthPlace, isEmpty);
    expect(p.birthPlaceId, isNull);
    expect(p.latitude, isNull);
    expect(p.longitude, isNull);
    expect(p.timezoneId, isNull);
    expect(p.timezoneResolutionStatus, BirthTimezoneStatus.missing);
    expect(p.hasKnownTime, isTrue);
    expect(
      BirthEvidenceClassifier.classify(BirthEvidence.fromProfile(p)),
      BirthEvidenceCompleteness.dateAndTimeNoPlace,
    );
  });

  test('round-trip toJson/fromJson keeps honest unknown flags', () {
    final original = BirthProfile(
      birthDate: DateTime(1992, 11, 10),
      birthPlace: '',
      birthTimeKnown: false,
      birthPlaceUnknownConfirmed: true,
    );
    final again = BirthProfile.fromJson(original.toJson());
    expect(again.birthTime, isNull);
    expect(again.birthPlace, isEmpty);
    expect(again.birthPlaceUnknownConfirmed, isTrue);
  });
}
