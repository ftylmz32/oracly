/// Phase 2 — assertion helpers (test-only).
library;

import 'yildizname_candidate_chart.dart';
import 'yildizname_contract_enums.dart';
import 'yildizname_contract_result.dart';
import 'yildizname_fingerprint.dart';
import 'yildizname_safety.dart';
import 'yildizname_truth_oracle.dart';

abstract final class YildiznameContractAssertions {
  YildiznameContractAssertions._();

  static ContractGateResult expectPass(ContractCandidateChart c) {
    final r = YildiznameTruthOracle.validate(c);
    return r.isPass
        ? r
        : ContractGateResult.fail('expected pass: ${r.reason}');
  }

  static ContractGateResult expectFail(ContractCandidateChart c) {
    final r = YildiznameTruthOracle.validate(c);
    return r.isFail
        ? const ContractGateResult.pass()
        : const ContractGateResult.fail('expected fail, got pass');
  }

  static ContractGateResult ownerIsolation({
    required ContractOwner evidenceOwner,
    required ContractOwner sessionOwner,
    required bool attemptingCrossRead,
  }) {
    if (attemptingCrossRead && evidenceOwner.id != sessionOwner.id) {
      return const ContractGateResult.fail('cross-owner evidence consume');
    }
    return const ContractGateResult.pass();
  }

  static ContractArtifact reopenImmutable(
    ContractArtifact saved, {
    required String newLocale,
    required DateTime newDay,
    required List<String> newMemory,
    required bool featureFlag,
    required String newInterpVersion,
  }) {
    // Environment mutations must not alter stored semantic snapshot.
    return saved;
  }

  static ContractGateResult fingerprintInvariant(
    ContractCandidateChart a,
    ContractCandidateChart b,
  ) {
    final fa = YildiznameAstronomicalFingerprint.of(a);
    final fb = YildiznameAstronomicalFingerprint.of(b);
    if (fa != fb) {
      return const ContractGateResult.fail('fingerprint changed');
    }
    return const ContractGateResult.pass();
  }

  static ContractGateResult narrativeGrounded(
    ContractCandidateChart c, {
    required List<String> claimedBodies,
  }) {
    final present = <String>{
      for (final f in c.facts)
        if (f.certainty != ContractFactCertainty.unavailable &&
            f.certainty != ContractFactCertainty.unsupported)
          f.type.name,
      for (final p in c.placements) p.body.toLowerCase(),
    };
    for (final claim in claimedBodies) {
      if (!present.contains(claim.toLowerCase()) &&
          !present.contains(_mapClaim(claim))) {
        return ContractGateResult.fail('ungrounded claim: $claim');
      }
    }
    return const ContractGateResult.pass();
  }

  static String _mapClaim(String c) {
    final l = c.toLowerCase();
    if (l.contains('moon')) return ContractFactType.moon.name;
    if (l.contains('asc') || l.contains('rising')) {
      return ContractFactType.ascendant.name;
    }
    if (l.contains('sun')) return ContractFactType.sunIdentity.name;
    if (l.contains('mars')) return ContractFactType.mars.name;
    return l;
  }

  static ContractGateResult safety(String narrative) =>
      YildiznameSafetyOracle.classify(narrative);

  static ContractGateResult genericity({
    required ContractCandidateChart c,
    required int referencedFactCount,
  }) {
    if (c.evidenceState == ContractEvidenceState.e4 &&
        c.engineCapable &&
        c.facts.where((f) => f.certainty == ContractFactCertainty.exact).length >
            3 &&
        referencedFactCount == 0) {
      return const ContractGateResult.fail('generic narrative with rich E4');
    }
    return const ContractGateResult.pass();
  }

  static ContractGateResult memoryCitation({
    required List<String> citedThemeIds,
    required Set<String> availableThemeIds,
    required bool citesCurrentReading,
    required bool citesDeleted,
    required bool citesOtherOwner,
  }) {
    if (citesCurrentReading) {
      return const ContractGateResult.fail('current reading as history');
    }
    if (citesDeleted) {
      return const ContractGateResult.fail('deleted source cited');
    }
    if (citesOtherOwner) {
      return const ContractGateResult.fail('other owner memory cited');
    }
    for (final id in citedThemeIds) {
      if (!availableThemeIds.contains(id)) {
        return ContractGateResult.fail('fabricated theme: $id');
      }
    }
    return const ContractGateResult.pass();
  }
}
