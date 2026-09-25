/// Phase 2 — candidate fact / placement / aspect (test-only).
library;

import 'yildizname_contract_enums.dart';

class ContractProvenance {
  const ContractProvenance({
    required this.engineId,
    required this.engineVersion,
    required this.evidenceFingerprint,
    required this.fidelity,
  });

  final String engineId;
  final String engineVersion;
  final String evidenceFingerprint;
  final ContractFidelity fidelity;
}

class ContractCandidateFact {
  const ContractCandidateFact({
    required this.type,
    required this.certainty,
    required this.fidelity,
    this.value,
    this.provenance,
    this.isLegacyPlaceholder = false,
  });

  final ContractFactType type;
  final ContractFactCertainty certainty;
  final ContractFidelity fidelity;
  final Object? value;
  final ContractProvenance? provenance;
  final bool isLegacyPlaceholder;
}

class ContractPlacement {
  const ContractPlacement({
    required this.body,
    required this.longitude,
    required this.signIndex,
    required this.degreeWithinSign,
    required this.certainty,
    this.house,
    this.retrograde,
    this.provenance,
  });

  final String body;
  final double longitude;
  final int signIndex;
  final double degreeWithinSign;
  final ContractFactCertainty certainty;
  final int? house;
  final bool? retrograde;
  final ContractProvenance? provenance;
}

class ContractAspect {
  const ContractAspect({
    required this.bodyA,
    required this.bodyB,
    required this.type,
    required this.orb,
    required this.certainty,
    this.provenance,
  });

  final String bodyA;
  final String bodyB;
  final String type;
  final double orb;
  final ContractFactCertainty certainty;
  final ContractProvenance? provenance;
}
