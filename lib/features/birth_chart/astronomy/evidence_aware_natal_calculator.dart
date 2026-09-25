/// Phase 4 — evidence-aware natal calculator (routes E1–E4).
library;

import '../evidence/birth_evidence.dart';
import '../evidence/birth_evidence_classifier.dart';
import '../evidence/birth_evidence_completeness.dart';
import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import '../models/chart_fidelity.dart';
import '../services/chart_calculation_port.dart';
import '../services/natal_chart_calculator.dart';
import 'astronomia_ephemeris_adapter.dart';
import 'astronomical_ephemeris_port.dart';
import 'astronomical_provenance.dart';
import 'birth_instant_resolution.dart';
import 'birth_instant_resolver.dart';
import 'evidence_fingerprint.dart';
import 'full_natal_evidence_builder.dart';
import 'natal_calculation_error.dart';
import 'natal_chart_assembler.dart';
import 'reduced_natal_evidence_builder.dart';

class EvidenceAwareNatalChartCalculator implements ChartCalculationPort {
  EvidenceAwareNatalChartCalculator({
    AstronomicalEphemerisPort? ephemeris,
    NatalChartCalculator? legacy,
  })  : _ephemeris = ephemeris ?? AstronomiaEphemerisAdapter(),
        _legacy = legacy ?? const NatalChartCalculator();

  final AstronomicalEphemerisPort _ephemeris;
  final NatalChartCalculator _legacy;

  @override
  String get calculationVersion => AstronomicalProvenance.calcYildiznameNatalV1;

  @override
  ChartCalculationFidelity get fidelity =>
      ChartCalculationFidelity.tropicalSunSign;

  @override
  ChartCalculationFidelity fidelityFor(BirthProfile profile) {
    final c = BirthEvidenceClassifier.classify(
      BirthEvidence.fromProfile(profile),
    );
    return switch (c) {
      BirthEvidenceCompleteness.dateAndPlaceNoTime =>
        ChartCalculationFidelity.reducedNatal,
      BirthEvidenceCompleteness.full =>
        ChartCalculationFidelity.fullNatalEphemeris,
      _ => ChartCalculationFidelity.tropicalSunSign,
    };
  }

  @override
  BirthChart calculate(BirthProfile profile) {
    final c = BirthEvidenceClassifier.classify(
      BirthEvidence.fromProfile(profile),
    );
    return switch (c) {
      BirthEvidenceCompleteness.dateAndPlaceNoTime => _e2(profile),
      BirthEvidenceCompleteness.full => _e4(profile),
      _ => _legacy.calculate(profile),
    };
  }

  BirthChart _e2(BirthProfile profile) {
    final tz = profile.timezoneId;
    if (tz == null || tz.isEmpty) return _legacy.calculate(profile);
    if (!NatalSupportedRange.containsCivilDate(profile.birthDate)) {
      throw const NatalDateUnsupportedException();
    }
    final evidence = ReducedNatalEvidenceBuilder.build(
      ephemeris: _ephemeris,
      birthDate: profile.birthDate,
      timezoneId: tz,
      fingerprint: EvidenceFingerprint.of(profile),
    );
    final legacy = _legacy.calculate(profile);
    return NatalChartAssembler.reduced(
      profile: profile,
      evidence: evidence,
      id: legacy.id,
    );
  }

  BirthChart _e4(BirthProfile profile) {
    if (!NatalSupportedRange.containsCivilDate(profile.birthDate)) {
      throw const NatalDateUnsupportedException();
    }
    final instant = BirthInstantResolver.resolve(profile);
    if (instant.kind == BirthInstantKind.nonexistent) {
      throw const NatalNonexistentLocalTimeException();
    }
    if (instant.kind == BirthInstantKind.ambiguous || !instant.isExact) {
      return _e2(profile);
    }
    final lat = profile.latitude;
    final lon = profile.longitude;
    if (lat == null || lon == null) return _legacy.calculate(profile);
    final evidence = FullNatalEvidenceBuilder.build(
      ephemeris: _ephemeris,
      utc: instant.utc!,
      latitude: lat,
      longitude: lon,
      fingerprint: EvidenceFingerprint.of(profile),
    );
    return NatalChartAssembler.full(profile: profile, evidence: evidence);
  }
}
