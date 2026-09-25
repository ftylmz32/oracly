/// Phase 2 — candidate chart + owner + artifact (test-only).
library;

import 'yildizname_candidate_fact.dart';
import 'yildizname_contract_enums.dart';
import 'yildizname_evidence_input.dart';

class ContractOwner {
  const ContractOwner(this.id);
  final String id;

  static const anonymousLocal = ContractOwner('anonymous_local');
}

class ContractCandidateChart {
  const ContractCandidateChart({
    required this.evidence,
    required this.evidenceState,
    required this.owner,
    required this.scope,
    required this.fidelity,
    required this.facts,
    this.placements = const [],
    this.aspects = const [],
    this.houseSystem,
    this.unavailableLayers = const [],
    this.engineCapable = false,
    this.narrative = '',
    this.narrativeLocale = 'tr',
    this.calculationVersion,
    this.interpretationVersion,
    this.schemaVersion = 'contract-1',
    this.discoveryThemes = const [],
    this.memoryThemeIds = const [],
    this.syntheticBirthTimeUsed = false,
    this.deviceTimezoneUsed = false,
    this.assumedPlaceUsed = false,
    this.dominantPlanetClaimed = false,
  });

  final ContractEvidenceInput evidence;
  final ContractEvidenceState evidenceState;
  final ContractOwner owner;
  final ContractScope scope;
  final ContractFidelity fidelity;
  final List<ContractCandidateFact> facts;
  final List<ContractPlacement> placements;
  final List<ContractAspect> aspects;
  final String? houseSystem;
  final List<String> unavailableLayers;
  final bool engineCapable;
  final String narrative;
  final String narrativeLocale;
  final String? calculationVersion;
  final String? interpretationVersion;
  final String schemaVersion;
  final List<String> discoveryThemes;
  final List<String> memoryThemeIds;
  final bool syntheticBirthTimeUsed;
  final bool deviceTimezoneUsed;
  final bool assumedPlaceUsed;
  final bool dominantPlanetClaimed;
}

class ContractArtifact {
  const ContractArtifact({
    required this.artifactId,
    required this.ownerId,
    required this.createdAt,
    required this.resultLocale,
    required this.evidenceFingerprint,
    required this.calculationFidelity,
    required this.calculationVersion,
    required this.interpretationVersion,
    required this.schemaVersion,
    required this.structuredFacts,
    required this.narrative,
    required this.source,
  });

  final String artifactId;
  final String ownerId;
  final DateTime createdAt;
  final String resultLocale;
  final String evidenceFingerprint;
  final ContractFidelity calculationFidelity;
  final String calculationVersion;
  final String interpretationVersion;
  final String schemaVersion;
  final Map<String, Object?> structuredFacts;
  final String narrative;
  final String source;

  ContractArtifact copyWith({
    String? narrative,
    Map<String, Object?>? structuredFacts,
    String? resultLocale,
    String? calculationVersion,
    String? interpretationVersion,
  }) =>
      ContractArtifact(
        artifactId: artifactId,
        ownerId: ownerId,
        createdAt: createdAt,
        resultLocale: resultLocale ?? this.resultLocale,
        evidenceFingerprint: evidenceFingerprint,
        calculationFidelity: calculationFidelity,
        calculationVersion: calculationVersion ?? this.calculationVersion,
        interpretationVersion:
            interpretationVersion ?? this.interpretationVersion,
        schemaVersion: schemaVersion,
        structuredFacts: structuredFacts ?? this.structuredFacts,
        narrative: narrative ?? this.narrative,
        source: source,
      );
}
