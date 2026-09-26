/// Phase 8A — provider payload must never carry raw birth/owner evidence.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_wire_contract.dart';

import 'phase8a_live_plan_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('S provider payload has no raw birth/location/owner fields', () {
    final plan = YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: 'owner-secret-uid',
      chart: phase8aChart(phase8aE4Profile()),
      languageCode: 'tr',
    );
    expect(plan.isNarrativeEligible, isTrue);
    final payload = YildiznameWireContract.payload(plan.request!);
    final blob = jsonEncode(payload).toLowerCase();

    for (final bad in [
      'birthdate',
      'birthtime',
      'birthplace',
      'latitude',
      'longitude',
      'timezoneid',
      'ownerid',
      'owner-secret-uid',
      'artifactid',
      'evidencefingerprint',
      'semanticfingerprint',
      'europe/istanbul',
      '41.0082',
      '28.9784',
      plan.evidenceFingerprint!.toLowerCase(),
    ]) {
      expect(blob.contains(bad), isFalse, reason: bad);
    }

    expect(payload.containsKey('narrative'), isTrue);
    expect(payload['language'], 'tr');
  });
}
