/// Phase 2 — candidate chart fixtures (test-only).
library;

import '../truth/yildizname_candidate_chart.dart';
import '../truth/yildizname_candidate_fact.dart';
import '../truth/yildizname_contract_enums.dart';
import 'evidence_fixtures.dart';

abstract final class CandidateChartFixtures {
  CandidateChartFixtures._();

  static ContractCandidateFact sunLegacy(String sign) => ContractCandidateFact(
        type: ContractFactType.sunIdentity,
        certainty: ContractFactCertainty.exact,
        fidelity: ContractFidelity.tropicalSunSign,
        value: sign,
        isLegacyPlaceholder: true,
      );

  static ContractCandidateChart e1ReducedSuccess() => ContractCandidateChart(
        evidence: EvidenceFixtures.e1,
        evidenceState: ContractEvidenceState.e1,
        owner: ContractOwner.anonymousLocal,
        scope: ContractScope.legacy,
        fidelity: ContractFidelity.tropicalSunSign,
        facts: [sunLegacy('Cancer')],
        unavailableLayers: const [
          'moon',
          'ascendant',
          'mc',
          'houses',
          'aspects',
          'planets',
        ],
        narrative: 'Güneş burcu üzerinden sembolik bir çerçeve.',
      );

  static ContractCandidateChart e2ReducedSuccess() => ContractCandidateChart(
        evidence: EvidenceFixtures.e2,
        evidenceState: ContractEvidenceState.e2,
        owner: ContractOwner.anonymousLocal,
        scope: ContractScope.reduced,
        fidelity: ContractFidelity.reducedNatal,
        facts: [
          sunLegacy('Cancer'),
          const ContractCandidateFact(
            type: ContractFactType.moon,
            certainty: ContractFactCertainty.intervalStable,
            fidelity: ContractFidelity.reducedNatal,
            value: 'Taurus',
          ),
          const ContractCandidateFact(
            type: ContractFactType.ascendant,
            certainty: ContractFactCertainty.unavailable,
            fidelity: ContractFidelity.reducedNatal,
          ),
        ],
        unavailableLayers: const ['ascendant', 'mc', 'houses'],
        narrative:
            'Doğum saati bilinmediği için yükselen ve evler bu yoruma dahil edilmedi.',
      );

  static ContractCandidateChart inventedMoonE1() => ContractCandidateChart(
        evidence: EvidenceFixtures.e1,
        evidenceState: ContractEvidenceState.e1,
        owner: ContractOwner.anonymousLocal,
        scope: ContractScope.legacy,
        fidelity: ContractFidelity.tropicalSunSign,
        facts: [
          sunLegacy('Cancer'),
          const ContractCandidateFact(
            type: ContractFactType.moon,
            certainty: ContractFactCertainty.exact,
            fidelity: ContractFidelity.fullNatalEphemeris,
            value: 'Scorpio',
          ),
        ],
        unavailableLayers: const ['ascendant'],
      );

  static ContractCandidateChart inventedAscE2() => ContractCandidateChart(
        evidence: EvidenceFixtures.e2,
        evidenceState: ContractEvidenceState.e2,
        owner: ContractOwner.anonymousLocal,
        scope: ContractScope.reduced,
        fidelity: ContractFidelity.reducedNatal,
        facts: [
          sunLegacy('Cancer'),
          const ContractCandidateFact(
            type: ContractFactType.ascendant,
            certainty: ContractFactCertainty.exact,
            fidelity: ContractFidelity.fullNatalEphemeris,
            value: 'Leo',
          ),
        ],
        unavailableLayers: const ['houses'],
      );

  static ContractCandidateChart e3WithAsc() => ContractCandidateChart(
        evidence: EvidenceFixtures.e3,
        evidenceState: ContractEvidenceState.e3,
        owner: ContractOwner.anonymousLocal,
        scope: ContractScope.full,
        fidelity: ContractFidelity.fullNatalEphemeris,
        facts: [
          sunLegacy('Cancer'),
          const ContractCandidateFact(
            type: ContractFactType.ascendant,
            certainty: ContractFactCertainty.exact,
            fidelity: ContractFidelity.fullNatalEphemeris,
            value: 'Leo',
          ),
        ],
        houseSystem: 'Placidus',
        unavailableLayers: const [],
        engineCapable: true,
      );

  static ContractCandidateChart e4NoEngine() => ContractCandidateChart(
        evidence: EvidenceFixtures.e4,
        evidenceState: ContractEvidenceState.e4,
        owner: ContractOwner.anonymousLocal,
        scope: ContractScope.reduced,
        fidelity: ContractFidelity.tropicalSunSign,
        facts: [
          sunLegacy('Cancer'),
          const ContractCandidateFact(
            type: ContractFactType.moon,
            certainty: ContractFactCertainty.unsupported,
            fidelity: ContractFidelity.fullNatalEphemeris,
          ),
        ],
        unavailableLayers: const ['moon', 'ascendant', 'houses', 'aspects'],
        engineCapable: false,
      );

  static ContractCandidateChart noonDefault() => ContractCandidateChart(
        evidence: EvidenceFixtures.e1,
        evidenceState: ContractEvidenceState.e1,
        owner: ContractOwner.anonymousLocal,
        scope: ContractScope.legacy,
        fidelity: ContractFidelity.tropicalSunSign,
        facts: [sunLegacy('Cancer')],
        unavailableLayers: const ['moon'],
        syntheticBirthTimeUsed: true,
      );
}
