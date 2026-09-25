/// Phase 4 — build E2 reducedNatal interval-safe evidence.
library;

import '../models/chart_fidelity.dart';
import '../models/element_balance.dart';
import '../models/zodiac_sign_id.dart';
import 'astronomical_ephemeris_port.dart';
import 'astronomical_fact_certainty.dart';
import 'astronomical_provenance.dart';
import 'birth_timezone_database.dart';
import 'natal_balance.dart';
import 'natal_body.dart';
import 'natal_calculation_metadata.dart';
import 'natal_chart_evidence.dart';
import 'natal_house_system.dart';
import 'natal_placement.dart';
import 'reduced_interval_calculator.dart';

abstract final class ReducedNatalEvidenceBuilder {
  ReducedNatalEvidenceBuilder._();

  static NatalChartEvidence build({
    required AstronomicalEphemerisPort ephemeris,
    required DateTime birthDate,
    required String timezoneId,
    required String fingerprint,
  }) {
    final provenance = AstronomicalProvenance(
      engineId: ephemeris.engineId,
      engineVersion: ephemeris.engineVersion,
      calculationVersion: AstronomicalProvenance.calcYildiznameNatalV1,
      evidenceFingerprint: fingerprint,
      zodiacSystem: AstronomicalProvenance.zodiacTropical,
      coordinateConvention: AstronomicalProvenance.coordApparentEclipticOfDate,
      timezoneDatabase: BirthTimezoneDatabase.label,
      houseSystem: NatalHouseSystem.wholeSign.name,
    );

    final samples = ReducedIntervalCalculator.localDayUtcSamples(
      birthDate: birthDate,
      timezoneId: timezoneId,
    );

    final placements = <NatalPlacement>[];
    for (final body in NatalBody.values) {
      final r = ReducedIntervalCalculator.classifyBody(
        ephemeris: ephemeris,
        body: body,
        utcSamples: samples,
      );
      if (r.certainty == AstronomicalFactCertainty.intervalStable &&
          r.sign is ZodiacSignId) {
        placements.add(NatalPlacement(
          body: body,
          sign: r.sign as ZodiacSignId,
          certainty: AstronomicalFactCertainty.intervalStable,
          provenance: provenance,
        ));
      } else {
        placements.add(NatalPlacement(
          body: body,
          certainty: r.certainty == AstronomicalFactCertainty.ambiguous
              ? AstronomicalFactCertainty.ambiguous
              : AstronomicalFactCertainty.unavailable,
          provenance: provenance,
        ));
      }
    }

    // Balance only from interval-stable signs.
    final stable = placements
        .where((p) => p.certainty == AstronomicalFactCertainty.intervalStable)
        .toList();
    final balance = stable.isEmpty
        ? NatalBalanceResult(
            elements: const ElementBalance(fire: 0, earth: 0, air: 0, water: 0),
            modalities: {
              ChartModality.cardinal: 0,
              ChartModality.fixed: 0,
              ChartModality.mutable: 0,
            },
            primaryElement: ChartElement.fire,
            primaryModality: ChartModality.cardinal,
          )
        : NatalBalance.fromPlacements(stable);

    return NatalChartEvidence(
      fidelity: ChartCalculationFidelity.reducedNatal,
      metadata: NatalCalculationMetadata(
        calculationVersion: AstronomicalProvenance.calcYildiznameNatalV1,
        engineId: ephemeris.engineId,
        engineVersion: ephemeris.engineVersion,
        evidenceFingerprint: fingerprint,
        houseSystem: NatalHouseSystem.wholeSign,
        zodiacSystem: AstronomicalProvenance.zodiacTropical,
        coordinateConvention: AstronomicalProvenance.coordApparentEclipticOfDate,
        timezoneDatabase: BirthTimezoneDatabase.label,
        birthInstantKind: 'unknown_time_interval',
      ),
      placements: placements,
      houses: const [],
      aspects: const [],
      elementBalance: balance.elements,
      modalityBalance: balance.modalities,
    );
  }
}
