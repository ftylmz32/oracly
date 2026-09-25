/// Phase 2 — owner isolation + known gap for ownerless birth key.
library;

import 'package:flutter_test/flutter_test.dart';

import 'truth/yildizname_candidate_chart.dart';
import 'truth/yildizname_contract_assertions.dart';
import 'truth/yildizname_contract_result.dart';

void main() {
  group('owner isolation', () {
    test('A→B cross-read FAIL', () {
      final r = YildiznameContractAssertions.ownerIsolation(
        evidenceOwner: const ContractOwner('ownerA'),
        sessionOwner: const ContractOwner('ownerB'),
        attemptingCrossRead: true,
      );
      expect(r.isFail, isTrue);
    });

    test('same owner read PASS', () {
      final r = YildiznameContractAssertions.ownerIsolation(
        evidenceOwner: const ContractOwner('ownerA'),
        sessionOwner: const ContractOwner('ownerA'),
        attemptingCrossRead: true,
      );
      expect(r.isPass, isTrue, reason: r.reason);
    });

    test('anonymous_local is a separate owner identity', () {
      expect(ContractOwner.anonymousLocal.id, 'anonymous_local');
      final cross = YildiznameContractAssertions.ownerIsolation(
        evidenceOwner: ContractOwner.anonymousLocal,
        sessionOwner: const ContractOwner('ownerA'),
        attemptingCrossRead: true,
      );
      expect(cross.isFail, isTrue);

      final sameAnon = YildiznameContractAssertions.ownerIsolation(
        evidenceOwner: ContractOwner.anonymousLocal,
        sessionOwner: ContractOwner.anonymousLocal,
        attemptingCrossRead: true,
      );
      expect(sameAnon.isPass, isTrue, reason: sameAnon.reason);
    });

    test('no cross-read attempt PASS even if owners differ', () {
      final r = YildiznameContractAssertions.ownerIsolation(
        evidenceOwner: const ContractOwner('ownerA'),
        sessionOwner: const ContractOwner('ownerB'),
        attemptingCrossRead: false,
      );
      expect(r.isPass, isTrue, reason: r.reason);
    });
  });

  group('known gaps', () {
    test('ownerless birth multi-artifact gap CLOSED by Phase 3/6', () {
      final gap = YildiznameKnownGaps.ownerlessBirthKey;
      expect(gap.isPass, isTrue);
      expect(gap.isKnownGap, isFalse);
      expect(gap.isFail, isFalse);
      expect(gap.reason, contains('CLOSED'));
    });
  });
}
