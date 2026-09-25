/// Tasks 42–43 — acquisition next-need + ask-once.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_evidence_acquisition.dart';
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

BirthEvidenceAcquisitionNeed _need(
  BirthEvidence e, {
  required bool timeAnswered,
}) =>
    BirthEvidenceAcquisitionPlan.nextNeedWithTimeAnswered(
      e,
      timeKnowledgeAnswered: timeAnswered,
    );

void main() {
  final d = DateTime(1992, 11, 10);
  final t = DateTime(1992, 11, 10, 8, 0);
  final place = _e(
    date: d,
    place: 'İzmir',
    lat: 38.42,
    lon: 27.14,
    tz: 'Europe/Istanbul',
    tzStatus: BirthTimezoneStatus.resolved,
  );

  test('Task 42 next-need progression', () {
    expect(_need(_e(), timeAnswered: false), BirthEvidenceAcquisitionNeed.birthDate);
    expect(_need(_e(date: d), timeAnswered: false),
        BirthEvidenceAcquisitionNeed.timeKnowledge);
    expect(
      _need(_e(date: d, timeKnown: true), timeAnswered: true),
      BirthEvidenceAcquisitionNeed.birthTime,
    );
    expect(
      _need(_e(date: d, time: t, timeKnown: true), timeAnswered: true),
      BirthEvidenceAcquisitionNeed.birthPlace,
    );
    expect(
      _need(_e(date: d, timeKnown: false), timeAnswered: true),
      BirthEvidenceAcquisitionNeed.birthPlace,
    );
    expect(
      _need(
        _e(date: d, timeKnown: false, placeUnknown: true),
        timeAnswered: true,
      ),
      BirthEvidenceAcquisitionNeed.none,
    );
    expect(
      _need(
        _e(
          date: d,
          time: t,
          timeKnown: true,
          place: place.birthPlace,
          lat: place.latitude,
          lon: place.longitude,
          tz: place.timezoneId,
          tzStatus: BirthTimezoneStatus.resolved,
        ),
        timeAnswered: true,
      ),
      BirthEvidenceAcquisitionNeed.none,
    );
  });

  test('Task 43 ask-once after persisted unknown answers', () {
    final timeUnknown = _e(date: d, timeKnown: false);
    expect(
      BirthEvidenceAcquisitionPlan.nextNeedPersisted(timeUnknown),
      BirthEvidenceAcquisitionNeed.birthPlace,
    );
    expect(
      BirthEvidenceAcquisitionPlan.nextNeedPersisted(
        _e(date: d, timeKnown: false, placeUnknown: true),
      ),
      BirthEvidenceAcquisitionNeed.none,
    );
    expect(
      BirthEvidenceAcquisitionPlan.nextNeedPersisted(place),
      isNot(BirthEvidenceAcquisitionNeed.timeKnowledge),
    );
  });
}
