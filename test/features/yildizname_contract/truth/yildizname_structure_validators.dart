/// Phase 2 — structured fact / placement / aspect validators (test-only).
library;

import 'yildizname_candidate_fact.dart';
import 'yildizname_contract_enums.dart';
import 'yildizname_contract_result.dart';

abstract final class YildiznameStructureValidators {
  YildiznameStructureValidators._();

  static ContractGateResult placement(ContractPlacement p) {
    if (p.longitude.isNaN || p.longitude.isInfinite) {
      return const ContractGateResult.fail('longitude NaN/Infinity');
    }
    if (p.longitude < 0 || p.longitude >= 360) {
      return const ContractGateResult.fail('longitude out of range');
    }
    if (p.degreeWithinSign < 0 || p.degreeWithinSign >= 30) {
      return const ContractGateResult.fail('degreeWithinSign out of range');
    }
    if (p.signIndex < 0 || p.signIndex > 11) {
      return const ContractGateResult.fail('signIndex out of range');
    }
    final expected = (p.longitude / 30).floor();
    if (expected != p.signIndex) {
      return const ContractGateResult.fail('sign/longitude mismatch');
    }
    if (p.house != null && (p.house! < 1 || p.house! > 12)) {
      return const ContractGateResult.fail('house out of range');
    }
    if (p.certainty == ContractFactCertainty.exact && p.provenance == null) {
      return const ContractGateResult.fail('exact placement missing provenance');
    }
    return const ContractGateResult.pass();
  }

  static ContractGateResult aspect(ContractAspect a) {
    if (a.bodyA.trim().isEmpty || a.bodyB.trim().isEmpty) {
      return const ContractGateResult.fail('aspect missing bodies');
    }
    if (a.bodyA == a.bodyB) {
      return const ContractGateResult.fail('self-aspect');
    }
    if (a.orb < 0 || a.orb.isNaN || a.orb.isInfinite) {
      return const ContractGateResult.fail('invalid orb');
    }
    if (a.type.trim().isEmpty) {
      return const ContractGateResult.fail('unknown aspect type');
    }
    return const ContractGateResult.pass();
  }

  static bool isLegacyPlaceholderDegree(num degree) => degree == 0;
  static bool isLegacyPlaceholderHouse(num house) => house == 0;

  static ContractGateResult durableId(String id) {
    if (id.isEmpty) return const ContractGateResult.fail('empty id');
    if (id.startsWith('Object.hash')) {
      return const ContractGateResult.fail('Object.hash not durable');
    }
    if (id.startsWith('locale:')) {
      return const ContractGateResult.fail('localized title id');
    }
    if (id.startsWith('now:')) {
      return const ContractGateResult.fail('DateTime.now alone');
    }
    return const ContractGateResult.pass();
  }
}
