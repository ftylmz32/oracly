/// Phase 2 — memory citation truth; themes do not alter fingerprint.
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixtures/artifact_fixtures.dart';
import 'fixtures/candidate_chart_fixtures.dart';
import 'truth/yildizname_candidate_chart.dart';
import 'truth/yildizname_contract_assertions.dart';
import 'truth/yildizname_fingerprint.dart';

void main() {
  group('memory citation rules', () {
    test('valid owned theme PASS', () {
      final r = YildiznameContractAssertions.memoryCitation(
        citedThemeIds: [MemoryFixtures.ownedA.theme],
        availableThemeIds: {MemoryFixtures.ownedA.theme},
        citesCurrentReading: false,
        citesDeleted: false,
        citesOtherOwner: false,
      );
      expect(r.isPass, isTrue, reason: r.reason);
    });

    test('fabricated theme FAIL', () {
      final r = YildiznameContractAssertions.memoryCitation(
        citedThemeIds: const ['invented-theme'],
        availableThemeIds: {MemoryFixtures.ownedA.theme},
        citesCurrentReading: false,
        citesDeleted: false,
        citesOtherOwner: false,
      );
      expect(r.isFail, isTrue);
    });

    test('current reading / deleted / other owner FAIL', () {
      expect(
        YildiznameContractAssertions.memoryCitation(
          citedThemeIds: const [],
          availableThemeIds: const {},
          citesCurrentReading: true,
          citesDeleted: false,
          citesOtherOwner: false,
        ).isFail,
        isTrue,
      );
      expect(
        YildiznameContractAssertions.memoryCitation(
          citedThemeIds: const [],
          availableThemeIds: const {},
          citesCurrentReading: false,
          citesDeleted: true,
          citesOtherOwner: false,
        ).isFail,
        isTrue,
      );
      expect(
        YildiznameContractAssertions.memoryCitation(
          citedThemeIds: const [],
          availableThemeIds: const {},
          citesCurrentReading: false,
          citesDeleted: false,
          citesOtherOwner: true,
        ).isFail,
        isTrue,
      );
    });
  });

  group('PersonalDiscovery themes', () {
    test('themes change narrative but NOT fingerprint', () {
      final base = CandidateChartFixtures.e1ReducedSuccess();
      final withThemes = ContractCandidateChart(
        evidence: base.evidence,
        evidenceState: base.evidenceState,
        owner: base.owner,
        scope: base.scope,
        fidelity: base.fidelity,
        facts: base.facts,
        unavailableLayers: base.unavailableLayers,
        narrative: 'Narrative shaped by discovery themes.',
        discoveryThemes: const ['boundaries', 'patience'],
        memoryThemeIds: const ['boundaries'],
      );
      expect(withThemes.narrative, isNot(base.narrative));
      expect(
        YildiznameAstronomicalFingerprint.of(base),
        YildiznameAstronomicalFingerprint.of(withThemes),
      );
    });

    test('empty history does not fabricate themes', () {
      final r = YildiznameContractAssertions.memoryCitation(
        citedThemeIds: const [],
        availableThemeIds: const {},
        citesCurrentReading: false,
        citesDeleted: false,
        citesOtherOwner: false,
      );
      expect(r.isPass, isTrue, reason: r.reason);
      expect(MemoryFixtures.deleted.deleted, isTrue);
      expect(MemoryFixtures.otherOwner.ownerId, isNot('ownerA'));
    });
  });
}
