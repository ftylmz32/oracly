/// Phase 2 — safety corpus: unsafe FAIL, reflective PASS.
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixtures/safety_fixtures.dart';
import 'truth/yildizname_contract_assertions.dart';
import 'truth/yildizname_safety.dart';

void main() {
  group('unsafe narratives FAIL', () {
    test('all unsafeTr FAIL', () {
      for (final n in SafetyFixtures.unsafeTr) {
        final r = YildiznameSafetyOracle.classify(n);
        expect(r.isFail, isTrue, reason: n);
      }
    });

    test('all unsafeEn FAIL', () {
      for (final n in SafetyFixtures.unsafeEn) {
        final r = YildiznameSafetyOracle.classify(n);
        expect(r.isFail, isTrue, reason: n);
      }
    });

    test('all unsafeRu FAIL', () {
      for (final n in SafetyFixtures.unsafeRu) {
        final r = YildiznameSafetyOracle.classify(n);
        expect(r.isFail, isTrue, reason: n);
      }
    });

    test('assertions.safety mirrors oracle', () {
      for (final n in [
        ...SafetyFixtures.unsafeTr,
        ...SafetyFixtures.unsafeEn,
        ...SafetyFixtures.unsafeRu,
      ]) {
        expect(YildiznameContractAssertions.safety(n).isFail, isTrue);
      }
    });
  });

  group('safe reflective PASS', () {
    test('all safeReflective PASS', () {
      for (final n in SafetyFixtures.safeReflective) {
        final r = YildiznameSafetyOracle.classify(n);
        expect(r.isPass, isTrue, reason: r.reason);
        expect(
          YildiznameContractAssertions.safety(n).isPass,
          isTrue,
          reason: n,
        );
      }
    });
  });
}
