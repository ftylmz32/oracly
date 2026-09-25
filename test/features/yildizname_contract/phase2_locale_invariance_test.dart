/// Phase 2 — locale invariance of astronomical fingerprint.
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixtures/candidate_chart_fixtures.dart';
import 'fixtures/evidence_fixtures.dart';
import 'truth/yildizname_candidate_chart.dart';
import 'truth/yildizname_candidate_fact.dart';
import 'truth/yildizname_contract_assertions.dart';
import 'truth/yildizname_contract_enums.dart';
import 'truth/yildizname_fingerprint.dart';

void main() {
  ContractCandidateChart localeChart(String locale, String narrative) {
    final base = CandidateChartFixtures.e1ReducedSuccess();
    return ContractCandidateChart(
      evidence: base.evidence,
      evidenceState: base.evidenceState,
      owner: base.owner,
      scope: base.scope,
      fidelity: base.fidelity,
      facts: base.facts,
      unavailableLayers: base.unavailableLayers,
      narrative: narrative,
      narrativeLocale: locale,
    );
  }

  test('same chart facts under tr/en/ru — fingerprint identical', () {
    final tr = localeChart('tr', 'Güneş burcu üzerinden sembolik çerçeve.');
    final en = localeChart('en', 'A symbolic frame from the sun sign.');
    final ru = localeChart('ru', 'Символическая рамка по солнечному знаку.');

    final ft = YildiznameAstronomicalFingerprint.of(tr);
    final fe = YildiznameAstronomicalFingerprint.of(en);
    final fr = YildiznameAstronomicalFingerprint.of(ru);

    expect(ft, fe);
    expect(fe, fr);

    final inv = YildiznameContractAssertions.fingerprintInvariant(tr, en);
    expect(inv.isPass, isTrue, reason: inv.reason);
  });

  test('only narrativeLocale may differ — facts unchanged', () {
    final a = localeChart('tr', 'A');
    final b = localeChart('en', 'B');
    expect(a.narrativeLocale, isNot(b.narrativeLocale));
    expect(a.narrative, isNot(b.narrative));
    expect(a.facts.map((f) => f.value), b.facts.map((f) => f.value));
    expect(
      YildiznameAstronomicalFingerprint.of(a),
      YildiznameAstronomicalFingerprint.of(b),
    );
  });

  test('e2 reduced also locale-invariant', () {
    final base = CandidateChartFixtures.e2ReducedSuccess();
    final tr = ContractCandidateChart(
      evidence: EvidenceFixtures.e2,
      evidenceState: ContractEvidenceState.e2,
      owner: base.owner,
      scope: base.scope,
      fidelity: base.fidelity,
      facts: base.facts,
      unavailableLayers: base.unavailableLayers,
      narrative: base.narrative,
      narrativeLocale: 'tr',
    );
    final en = ContractCandidateChart(
      evidence: EvidenceFixtures.e2,
      evidenceState: ContractEvidenceState.e2,
      owner: base.owner,
      scope: base.scope,
      fidelity: base.fidelity,
      facts: List<ContractCandidateFact>.from(base.facts),
      unavailableLayers: base.unavailableLayers,
      narrative: 'English narrative',
      narrativeLocale: 'en',
    );
    expect(
      YildiznameAstronomicalFingerprint.of(tr),
      YildiznameAstronomicalFingerprint.of(en),
    );
  });
}
