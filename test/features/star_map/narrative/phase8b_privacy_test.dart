/// Phase 8B — provider payload privacy during orchestration.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';

import 'fixtures/fake_yildizname_ai.dart';
import 'phase8b_test_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('S provider payload forbids birth/owner/fingerprints', () async {
    final storage = phase8bStorage();
    Map<String, dynamic>? seen;
    final ai = FakeYildiznameAi(({
      required payload,
      required fingerprint,
      required attempt,
    }) async {
      seen = Map<String, dynamic>.from(payload);
      return failProvider();
    });
    await phase8bOrchestrator(
      storage: storage,
      chart: phase8bE2(),
      ai: ai,
      generate: null,
    ).execute(languageCode: 'en');
    expect(seen, isNotNull);
    final encoded = seen.toString().toLowerCase();
    for (final banned in [
      'birthdate',
      'birthtime',
      'birthplace',
      'timezoneid',
      'ownerid',
      'artifactid',
      'evidencefingerprint',
      'semanticfingerprint',
    ]) {
      expect(encoded.contains(banned), isFalse, reason: banned);
    }
    for (final key in [
      'birthDate',
      'birthTime',
      'birthPlace',
      'lat',
      'lon',
      'latitude',
      'longitude',
      'timezoneId',
      'ownerId',
      'artifactId',
      'evidenceFingerprint',
      'semanticFingerprint',
    ]) {
      expect(seen!.containsKey(key), isFalse, reason: key);
    }
    expect(seen!.containsKey('narrative'), isTrue);
  });
}
