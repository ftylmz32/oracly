/// Task 41 — BirthEvidenceClassifier input matrix.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence_classifier.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence_completeness.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';

BirthEvidence _e({
  DateTime? date,
  DateTime? time,
  bool timeKnown = false,
  String place = '',
  double? lat,
  double? lon,
  String? tz,
  BirthTimezoneStatus tzStatus = BirthTimezoneStatus.missing,
  bool placeUnknown = false,
}) =>
    BirthEvidence(
      ownerId: null,
      birthDate: date,
      birthTime: time,
      timeKnown: timeKnown,
      birthPlace: place,
      latitude: lat,
      longitude: lon,
      timezoneId: tz,
      timezoneStatus: tzStatus,
      birthPlaceUnknownConfirmed: placeUnknown,
    );

BirthEvidenceCompleteness _c(BirthEvidence e) =>
    BirthEvidenceClassifier.classify(e);

void main() {
  final d = DateTime(1990, 3, 25);
  final t = DateTime(1990, 3, 25, 9, 15);

  test('Task 41 classifier matrix permutations', () {
    expect(_c(_e()), BirthEvidenceCompleteness.missingDate);
    expect(_c(_e(date: d)), BirthEvidenceCompleteness.dateOnly);
    expect(
      _c(_e(date: d, timeKnown: false, placeUnknown: true)),
      BirthEvidenceCompleteness.dateOnly,
    );
    expect(
      _c(_e(
        date: d,
        place: 'Ankara',
        lat: 39.93,
        lon: 32.85,
        tz: 'Europe/Istanbul',
        tzStatus: BirthTimezoneStatus.resolved,
      )),
      BirthEvidenceCompleteness.dateAndPlaceNoTime,
    );
    expect(
      _c(_e(date: d, time: t, timeKnown: true)),
      BirthEvidenceCompleteness.dateAndTimeNoPlace,
    );
    expect(
      _c(_e(
        date: d,
        time: t,
        timeKnown: true,
        place: 'Ankara',
        lat: 39.93,
        lon: 32.85,
        tz: 'Europe/Istanbul',
        tzStatus: BirthTimezoneStatus.resolved,
      )),
      BirthEvidenceCompleteness.full,
    );
    // Incomplete place evidence stays dateOnly / E3 — never invented E2/E4.
    expect(
      _c(_e(date: d, place: 'Ankara')),
      BirthEvidenceCompleteness.dateOnly,
    );
    expect(
      _c(_e(date: d, lat: 39.93, lon: 32.85)),
      BirthEvidenceCompleteness.dateOnly,
    );
    expect(
      _c(_e(
        date: d,
        place: 'Ankara',
        tz: 'Europe/Istanbul',
        tzStatus: BirthTimezoneStatus.resolved,
      )),
      BirthEvidenceCompleteness.dateOnly,
    );
    expect(
      _c(_e(date: d, timeKnown: true, time: null)),
      BirthEvidenceCompleteness.dateOnly,
    );
    expect(
      _c(_e(date: d, timeKnown: false, time: t)),
      BirthEvidenceCompleteness.dateOnly,
    );
    expect(
      _c(_e(
        date: d,
        time: t,
        timeKnown: true,
        place: 'Ankara',
        lat: 39.93,
        lon: 32.85,
        tz: 'Europe/Istanbul',
        tzStatus: BirthTimezoneStatus.failed,
      )),
      BirthEvidenceCompleteness.dateAndTimeNoPlace,
    );
  });
}
