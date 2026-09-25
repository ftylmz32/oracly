/// Phase 2 — artifact / memory / timezone fixtures (test-only).
library;

import '../truth/yildizname_candidate_chart.dart';
import '../truth/yildizname_contract_enums.dart';

abstract final class ArtifactFixtures {
  ArtifactFixtures._();

  static ContractArtifact sampleA() => ContractArtifact(
        artifactId: 'art-uuid-001',
        ownerId: 'ownerA',
        createdAt: DateTime.utc(2026, 1, 10, 12),
        resultLocale: 'tr',
        evidenceFingerprint: 'ev-fp-1',
        calculationFidelity: ContractFidelity.tropicalSunSign,
        calculationVersion: 'calc-A',
        interpretationVersion: 'interp-A',
        schemaVersion: 'contract-1',
        structuredFacts: const {'sun': 'Cancer'},
        narrative: 'Narrative A',
        source: 'yildizname_contract',
      );

  static const validDurableIds = ['art-uuid-001', 'digest:sha256:abc'];
  static const invalidDurableIds = [
    'Object.hash(title,insight)',
    'locale:Güneş Burcu',
    'now:2026-09-25',
  ];
}

class MemoryEvidenceRecord {
  const MemoryEvidenceRecord({
    required this.sourceId,
    required this.ownerId,
    required this.createdAt,
    required this.theme,
    this.deleted = false,
  });

  final String sourceId;
  final String ownerId;
  final DateTime createdAt;
  final String theme;
  final bool deleted;
}

abstract final class MemoryFixtures {
  MemoryFixtures._();

  static final ownedA = MemoryEvidenceRecord(
    sourceId: 'src-1',
    ownerId: 'ownerA',
    createdAt: DateTime.utc(2025, 6, 1),
    theme: 'boundaries',
  );

  static final deleted = MemoryEvidenceRecord(
    sourceId: 'src-2',
    ownerId: 'ownerA',
    createdAt: DateTime.utc(2025, 5, 1),
    theme: 'boundaries',
    deleted: true,
  );

  static final otherOwner = MemoryEvidenceRecord(
    sourceId: 'src-3',
    ownerId: 'ownerB',
    createdAt: DateTime.utc(2025, 4, 1),
    theme: 'boundaries',
  );
}

abstract final class TimezoneFixtures {
  TimezoneFixtures._();

  static const missingId = <String, Object?>{
    'timezoneId': null,
    'historicalOffsetMinutes': null,
  };

  static const resolved = <String, Object?>{
    'timezoneId': 'Europe/Istanbul',
    'historicalOffsetMinutes': 180,
  };
}
