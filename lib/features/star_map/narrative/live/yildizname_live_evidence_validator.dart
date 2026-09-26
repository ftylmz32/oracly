/// Phase 8A.1/8A.2 — pure authoritative evidence provenance + shape preflight.
library;

import '../../../birth_chart/astronomy/astronomia_ephemeris_adapter.dart';
import '../../../birth_chart/astronomy/astronomical_fact_certainty.dart';
import '../../../birth_chart/astronomy/astronomical_provenance.dart';
import '../../../birth_chart/astronomy/birth_timezone_database.dart';
import '../../../birth_chart/astronomy/evidence_fingerprint.dart';
import '../../../birth_chart/astronomy/natal_body.dart';
import '../../../birth_chart/astronomy/natal_chart_evidence.dart';
import '../../../birth_chart/astronomy/natal_house_system.dart';
import '../../../birth_chart/astronomy/natal_placement.dart';
import '../../../birth_chart/models/birth_chart.dart';
import '../../../birth_chart/models/chart_fidelity.dart';
import 'yildizname_live_evidence_fact_check.dart';
import 'yildizname_live_evidence_shape.dart';

/// Fail-closed local preflight — no provider, no astronomy recompute.
abstract final class YildiznameLiveEvidenceValidator {
  YildiznameLiveEvidenceValidator._();

  static bool isCoherent(BirthChart chart, NatalChartEvidence evidence) {
    if (chart.fidelity != evidence.fidelity) return false;
    if (evidence.fidelity != ChartCalculationFidelity.reducedNatal &&
        evidence.fidelity != ChartCalculationFidelity.fullNatalEphemeris) {
      return false;
    }
    if (!_metadataMatchesContract(chart, evidence)) return false;
    if (!_birthInstantMatches(evidence)) return false;
    if (!_reducedStructureOk(evidence)) return false;
    if (!YildiznameLiveEvidenceFactCheck.factsMatchMetadata(evidence)) {
      return false;
    }
    return YildiznameLiveEvidenceShape.isStructurallySound(evidence);
  }

  static bool _metadataMatchesContract(
    BirthChart chart,
    NatalChartEvidence evidence,
  ) {
    final meta = evidence.metadata;
    if (meta.engineId.trim().isEmpty) return false;
    if (meta.engineId != AstronomicalProvenance.engineAstronomia) return false;
    if (meta.engineVersion.trim().isEmpty) return false;
    if (meta.engineVersion != AstronomiaEphemerisAdapter.version) return false;
    if (meta.calculationVersion !=
        AstronomicalProvenance.calcYildiznameNatalV1) {
      return false;
    }
    if (meta.zodiacSystem != AstronomicalProvenance.zodiacTropical) {
      return false;
    }
    if (meta.coordinateConvention !=
        AstronomicalProvenance.coordApparentEclipticOfDate) {
      return false;
    }
    if (meta.houseSystem != NatalHouseSystem.wholeSign) return false;
    if (evidence.houseSystem != NatalHouseSystem.wholeSign) return false;
    if (meta.timezoneDatabase != BirthTimezoneDatabase.label) return false;
    final fp = meta.evidenceFingerprint.trim();
    if (fp.isEmpty) return false;
    return fp == EvidenceFingerprint.of(chart.profile);
  }

  static bool _birthInstantMatches(NatalChartEvidence evidence) {
    final meta = evidence.metadata;
    if (evidence.fidelity == ChartCalculationFidelity.reducedNatal) {
      return meta.birthInstantKind == 'unknown_time_interval';
    }
    if (evidence.fidelity == ChartCalculationFidelity.fullNatalEphemeris) {
      if (meta.birthInstantKind != 'exact') return false;
      final iso = meta.utcInstantIso?.trim() ?? '';
      if (iso.isEmpty) return false;
      try {
        final parsed = DateTime.parse(iso);
        return parsed.isUtc;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  static bool _reducedStructureOk(NatalChartEvidence evidence) {
    if (evidence.fidelity != ChartCalculationFidelity.reducedNatal) {
      return true;
    }
    if (evidence.ascendant != null || evidence.midheaven != null) return false;
    if (evidence.houses.isNotEmpty || evidence.aspects.isNotEmpty) return false;
    if (evidence.placements.length != NatalBody.values.length) return false;
    for (final p in evidence.placements) {
      if (!_reducedPlacementOk(p)) return false;
    }
    return true;
  }

  static bool _reducedPlacementOk(NatalPlacement p) {
    final hasExact = p.longitude != null ||
        p.degreeWithinSign != null ||
        p.retrograde != null ||
        p.house != null;
    if (p.certainty == AstronomicalFactCertainty.intervalStable) {
      if (hasExact) return false;
      return p.sign != null;
    }
    if (p.certainty == AstronomicalFactCertainty.ambiguous ||
        p.certainty == AstronomicalFactCertainty.unavailable ||
        p.certainty == AstronomicalFactCertainty.unsupported) {
      if (hasExact) return false;
      return p.sign == null;
    }
    return false;
  }
}
