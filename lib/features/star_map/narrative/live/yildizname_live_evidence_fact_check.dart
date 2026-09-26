/// Phase 8A.1/8A.2 — fact-level provenance must match evidence metadata envelope.
library;

import '../../../birth_chart/astronomy/astronomical_provenance.dart';
import '../../../birth_chart/astronomy/natal_calculation_metadata.dart';
import '../../../birth_chart/astronomy/natal_chart_evidence.dart';
import '../../../birth_chart/astronomy/natal_house_system.dart';

abstract final class YildiznameLiveEvidenceFactCheck {
  YildiznameLiveEvidenceFactCheck._();

  static bool factsMatchMetadata(NatalChartEvidence evidence) {
    final meta = evidence.metadata;
    for (final p in evidence.placements) {
      if (!_matches(meta, p.provenance)) return false;
    }
    final asc = evidence.ascendant;
    if (asc != null && !_matches(meta, asc.provenance)) return false;
    final mc = evidence.midheaven;
    if (mc != null && !_matches(meta, mc.provenance)) return false;
    for (final h in evidence.houses) {
      if (h.system != NatalHouseSystem.wholeSign) return false;
      if (!_matches(meta, h.provenance)) return false;
    }
    for (final a in evidence.aspects) {
      if (!_matches(meta, a.provenance)) return false;
    }
    return true;
  }

  static bool _matches(
    NatalCalculationMetadata meta,
    AstronomicalProvenance p,
  ) {
    if (p.engineId != meta.engineId) return false;
    if (p.engineVersion != meta.engineVersion) return false;
    if (p.calculationVersion != meta.calculationVersion) return false;
    if (p.evidenceFingerprint != meta.evidenceFingerprint) return false;
    if (p.zodiacSystem != meta.zodiacSystem) return false;
    if (p.coordinateConvention != meta.coordinateConvention) return false;
    if (p.timezoneDatabase != meta.timezoneDatabase) return false;
    // Phase 4 producers always stamp wholeSign — null is corrupt.
    if (p.houseSystem != meta.houseSystem.name) return false;
    if (p.houseSystem != NatalHouseSystem.wholeSign.name) return false;
    return true;
  }
}
