/// Phase 2 — astronomical fixture manifest + known-gap ledger.
///
/// Live "today" sky / transit outputs are Astrology product concerns.
/// Frozen Yıldızname artifacts are immutable snapshots — never recomputed
/// against "today" (see ArtifactFixtures + reopenImmutable).
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixtures/astronomical_fixture_manifest.dart';
import 'fixtures/candidate_chart_fixtures.dart';
import 'truth/yildizname_contract_assertions.dart';
import 'truth/yildizname_contract_result.dart';
import 'truth/yildizname_interval.dart';
import 'truth/yildizname_truth_oracle.dart';

void main() {
  test('all 8 categories PENDING_AUTHORITY', () {
    expect(AstronomicalFixtureManifest.categories, hasLength(8));
    for (final c in AstronomicalFixtureManifest.categories) {
      expect(c.authority, FixtureAuthority.pendingAuthority);
      expect(c.requiredFields, contains('source'));
      expect(c.requiredFields, contains('expectedValues'));
    }
  });

  test('inventedAuthoritativeValues is false', () {
    expect(AstronomicalFixtureManifest.inventedAuthoritativeValues, isFalse);
    expect(
      AstronomicalFixtureManifest.legacyDateTableLabel,
      'LEGACY DATE TABLE',
    );
  });

  test('known gaps ledger non-empty', () {
    expect(YildiznameKnownGaps.all, isNotEmpty);
    for (final gap in YildiznameKnownGaps.all) {
      expect(gap.isKnownGap, isTrue);
      expect(gap.isFail, isFalse);
    }
  });

  test('interval stable vs ambiguous fixtures', () {
    final stable = YildiznameIntervalOracle.classify(const [
      IntervalSample(label: '00:00', value: 'Taurus'),
      IntervalSample(label: '12:00', value: 'Taurus'),
      IntervalSample(label: '23:59', value: 'Taurus'),
    ]);
    expect(stable.name, 'intervalStable');
    final ambiguous = YildiznameIntervalOracle.classify(const [
      IntervalSample(label: '00:00', value: 'Taurus'),
      IntervalSample(label: '12:00', value: 'Gemini'),
    ]);
    expect(ambiguous.name, 'ambiguous');
    expect(
      YildiznameIntervalOracle.chosenValue(const [
        IntervalSample(label: 'a', value: 'Taurus'),
        IntervalSample(label: 'b', value: 'Gemini'),
      ]),
      isNull,
    );
  });

  test('e4 without engine → unsupported layers ok', () {
    final r = YildiznameTruthOracle.validate(
      CandidateChartFixtures.e4NoEngine(),
    );
    expect(r.isPass, isTrue, reason: r.reason);
  });

  test('genericity and groundedness', () {
    final ok = CandidateChartFixtures.e1ReducedSuccess();
    expect(
      YildiznameContractAssertions.genericity(
        c: ok,
        referencedFactCount: 1,
      ).isPass,
      isTrue,
    );
    final grounded = YildiznameContractAssertions.narrativeGrounded(
      ok,
      claimedBodies: const ['sun'],
    );
    expect(grounded.isPass, isTrue, reason: grounded.reason);
    final ungrounded = YildiznameContractAssertions.narrativeGrounded(
      ok,
      claimedBodies: const ['moon'],
    );
    expect(ungrounded.isFail, isTrue);
  });
}
