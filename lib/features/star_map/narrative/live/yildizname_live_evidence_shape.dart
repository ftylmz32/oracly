/// Phase 8A.2 — structural shape attestation (no astronomy recompute).
library;

import '../../../birth_chart/astronomy/astronomical_fact_certainty.dart';
import '../../../birth_chart/astronomy/natal_angle.dart';
import '../../../birth_chart/astronomy/natal_aspect.dart';
import '../../../birth_chart/astronomy/natal_body.dart';
import '../../../birth_chart/astronomy/natal_chart_evidence.dart';
import '../../../birth_chart/astronomy/natal_house.dart';
import '../../../birth_chart/astronomy/natal_house_system.dart';
import '../../../birth_chart/astronomy/natal_placement.dart';
import '../../../birth_chart/models/chart_fidelity.dart';

abstract final class YildiznameLiveEvidenceShape {
  YildiznameLiveEvidenceShape._();

  static bool isStructurallySound(NatalChartEvidence evidence) {
    if (!_bodyInventoryOk(evidence.placements)) return false;
    if (!_balancesOk(evidence)) return false;
    if (evidence.fidelity == ChartCalculationFidelity.reducedNatal) {
      return true; // reduced placement rules live in the validator
    }
    if (evidence.fidelity != ChartCalculationFidelity.fullNatalEphemeris) {
      return false;
    }
    if (!_fullPlacementsOk(evidence.placements)) return false;
    if (!_ascOk(evidence.ascendant)) return false;
    if (!_mcOk(evidence.midheaven)) return false;
    if (!_housesOk(evidence.houses)) return false;
    return _aspectsOk(evidence.aspects);
  }

  static bool _bodyInventoryOk(List<NatalPlacement> placements) {
    if (placements.length != NatalBody.values.length) return false;
    final seen = <NatalBody>{};
    for (final p in placements) {
      if (!seen.add(p.body)) return false;
    }
    return seen.length == NatalBody.values.length;
  }

  static bool _balancesOk(NatalChartEvidence evidence) {
    final e = evidence.elementBalance;
    if (e.fire < 0 || e.earth < 0 || e.air < 0 || e.water < 0) return false;
    for (final v in evidence.modalityBalance.values) {
      if (v < 0) return false;
    }
    return true;
  }

  static bool _fullPlacementsOk(List<NatalPlacement> placements) {
    for (final p in placements) {
      if (p.certainty != AstronomicalFactCertainty.exact) return false;
      if (p.sign == null) return false;
      if (p.longitude == null || p.degreeWithinSign == null || p.house == null) {
        return false;
      }
      // Frozen FullNatalEvidenceBuilder: Sun/Moon never stamp retrograde.
      if (p.body == NatalBody.sun || p.body == NatalBody.moon) {
        if (p.retrograde != null) return false;
      } else if (p.retrograde == null) {
        return false;
      }
      if (!_lonOk(p.longitude!) || !_degOk(p.degreeWithinSign!)) return false;
      if (!_houseNumOk(p.house!)) return false;
    }
    return true;
  }

  static bool _ascOk(NatalAngle? asc) {
    if (asc == null) return false;
    if (asc.kind != NatalAngleKind.ascendant) return false;
    if (asc.certainty != AstronomicalFactCertainty.exact) return false;
    if (!_lonOk(asc.longitude) || !_degOk(asc.degreeWithinSign)) return false;
    return asc.house == 1;
  }

  static bool _mcOk(NatalAngle? mc) {
    if (mc == null) return false;
    if (mc.kind != NatalAngleKind.midheaven) return false;
    if (mc.certainty != AstronomicalFactCertainty.exact) return false;
    if (!_lonOk(mc.longitude) || !_degOk(mc.degreeWithinSign)) return false;
    final h = mc.house;
    return h != null && _houseNumOk(h);
  }

  static bool _housesOk(List<NatalHouse> houses) {
    if (houses.length != 12) return false;
    final nums = <int>{};
    for (final h in houses) {
      if (!_houseNumOk(h.number)) return false;
      if (!nums.add(h.number)) return false;
      if (h.system != NatalHouseSystem.wholeSign) return false;
      if (h.certainty != AstronomicalFactCertainty.exact) return false;
      if (!_lonOk(h.cuspLongitude)) return false;
    }
    return nums.length == 12;
  }

  static bool _aspectsOk(List<NatalAspect> aspects) {
    for (final a in aspects) {
      if (a.certainty != AstronomicalFactCertainty.exact) return false;
      if (a.bodyA == a.bodyB) return false;
      if (!a.orb.isFinite || a.orb < 0) return false;
    }
    return true;
  }

  static bool _lonOk(double v) => v.isFinite && v >= 0 && v < 360;
  static bool _degOk(double v) => v.isFinite && v >= 0 && v < 30;
  static bool _houseNumOk(int h) => h >= 1 && h <= 12;
}
