/// Phase 2 — truth oracle: validates candidate charts against matrix.
library;

import 'yildizname_candidate_chart.dart';
import 'yildizname_candidate_fact.dart';
import 'yildizname_contract_enums.dart';
import 'yildizname_contract_result.dart';
import 'yildizname_evidence_input.dart';
import 'yildizname_fact_matrix.dart';
import 'yildizname_structure_validators.dart';

abstract final class YildiznameTruthOracle {
  YildiznameTruthOracle._();

  static ContractGateResult validate(ContractCandidateChart c) {
    final classified = YildiznameEvidenceClassifier.classify(c.evidence);
    if (classified != c.evidenceState) {
      return ContractGateResult.fail(
        'evidenceState mismatch: claimed ${c.evidenceState} got $classified',
      );
    }
    final synth = assertNoSyntheticBirthTime(c);
    if (synth.isFail) return synth;
    if (c.deviceTimezoneUsed) {
      return const ContractGateResult.fail('device timezone used as birth TZ');
    }
    if (c.assumedPlaceUsed) {
      return const ContractGateResult.fail('assumed place');
    }
    if (c.dominantPlanetClaimed && c.evidenceState == ContractEvidenceState.e1) {
      return const ContractGateResult.fail('dominant planet without evidence');
    }
    for (final f in c.facts) {
      final r = _fact(c.evidenceState, f, c.engineCapable);
      if (r.isFail) return r;
    }
    for (final p in c.placements) {
      final r = YildiznameStructureValidators.placement(p);
      if (r.isFail) return r;
    }
    for (final a in c.aspects) {
      final r = YildiznameStructureValidators.aspect(a);
      if (r.isFail) return r;
    }
    if (c.placements.any((p) => p.house != null) && c.houseSystem == null) {
      return const ContractGateResult.fail('houses without houseSystem');
    }
    if (c.scope == ContractScope.full && !c.engineCapable) {
      return const ContractGateResult.fail(
        'full scope claimed without calculation support',
      );
    }
    if ((c.scope == ContractScope.reduced ||
            c.scope == ContractScope.legacy) &&
        c.unavailableLayers.isEmpty &&
        c.evidenceState != ContractEvidenceState.e4) {
      return const ContractGateResult.fail('reduced scope missing disclosure');
    }
    return const ContractGateResult.pass();
  }

  static ContractGateResult assertNoSyntheticBirthTime(ContractCandidateChart c) {
    if (c.syntheticBirthTimeUsed) {
      return const ContractGateResult.fail('synthetic birth time');
    }
    if (!c.evidence.timeKnown && c.evidence.usedSyntheticBirthTime) {
      return const ContractGateResult.fail('synthetic birth time flag');
    }
    return const ContractGateResult.pass();
  }

  static ContractGateResult _fact(
    ContractEvidenceState e,
    ContractCandidateFact f,
    bool engineCapable,
  ) {
    final cell = YildiznameFactMatrix.cell(f.type, e);
    if (!cell.allowed) {
      if (f.certainty == ContractFactCertainty.unavailable ||
          f.certainty == ContractFactCertainty.unsupported) {
        return const ContractGateResult.pass();
      }
      return ContractGateResult.fail('${f.type} not allowed at $e');
    }
    if (cell.allowedCertainty.isNotEmpty &&
        !cell.allowedCertainty.contains(f.certainty)) {
      return ContractGateResult.fail(
        '${f.type} certainty ${f.certainty} not allowed at $e',
      );
    }
    if (f.certainty == ContractFactCertainty.exact &&
        !engineCapable &&
        f.fidelity != ContractFidelity.tropicalSunSign &&
        !f.isLegacyPlaceholder) {
      return ContractGateResult.fail(
        '${f.type} exact without engine → must be unsupported',
      );
    }
    if (f.certainty == ContractFactCertainty.exact &&
        f.fidelity != ContractFidelity.tropicalSunSign &&
        !f.isLegacyPlaceholder &&
        f.provenance == null) {
      return const ContractGateResult.fail('new-format exact missing provenance');
    }
    return const ContractGateResult.pass();
  }
}
