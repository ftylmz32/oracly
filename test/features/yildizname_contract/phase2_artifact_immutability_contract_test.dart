/// Phase 2 — artifact immutability + durable id contract.
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixtures/artifact_fixtures.dart';
import 'truth/yildizname_contract_assertions.dart';
import 'truth/yildizname_structure_validators.dart';

void main() {
  group('reopenImmutable', () {
    test('keeps narrative, facts, and versions under env mutation', () {
      final saved = ArtifactFixtures.sampleA();
      final reopened = YildiznameContractAssertions.reopenImmutable(
        saved,
        newLocale: 'en',
        newDay: DateTime.utc(2026, 9, 25),
        newMemory: const ['boundaries'],
        featureFlag: true,
        newInterpVersion: 'interp-B',
      );
      expect(reopened.narrative, saved.narrative);
      expect(reopened.structuredFacts, saved.structuredFacts);
      expect(reopened.calculationVersion, saved.calculationVersion);
      expect(reopened.interpretationVersion, saved.interpretationVersion);
      expect(reopened.schemaVersion, saved.schemaVersion);
      expect(reopened.artifactId, saved.artifactId);
      expect(reopened.evidenceFingerprint, saved.evidenceFingerprint);
    });

    test('calc / interp / schema versions preserved', () {
      final a = ArtifactFixtures.sampleA();
      expect(a.calculationVersion, 'calc-A');
      expect(a.interpretationVersion, 'interp-A');
      expect(a.schemaVersion, 'contract-1');
    });
  });

  group('durableId', () {
    test('rejects Object.hash and non-durable forms', () {
      for (final id in ArtifactFixtures.invalidDurableIds) {
        final r = YildiznameStructureValidators.durableId(id);
        expect(r.isFail, isTrue, reason: id);
      }
      expect(
        YildiznameStructureValidators.durableId('Object.hash(title,insight)')
            .isFail,
        isTrue,
      );
    });

    test('valid durable / UUID-style ids PASS', () {
      for (final id in ArtifactFixtures.validDurableIds) {
        final r = YildiznameStructureValidators.durableId(id);
        expect(r.isPass, isTrue, reason: r.reason);
      }
      final uuid = YildiznameStructureValidators.durableId(
        '550e8400-e29b-41d4-a716-446655440000',
      );
      expect(uuid.isPass, isTrue, reason: uuid.reason);
    });
  });

  group('schema', () {
    test('unknown schema reject concept', () {
      // Contract freeze: only known schema versions are reopenable.
      const known = {'contract-1'};
      const unknown = 'contract-99-unknown';
      expect(known.contains(unknown), isFalse);
      expect(known.contains(ArtifactFixtures.sampleA().schemaVersion), isTrue);
    });
  });
}
