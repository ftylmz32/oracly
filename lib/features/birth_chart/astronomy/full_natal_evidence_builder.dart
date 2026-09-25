/// Phase 4 — build exact E4 structured evidence from UTC instant.
library;

import '../models/chart_fidelity.dart';
import '../models/zodiac_sign_id.dart';
import 'angle_calculator.dart';
import 'astronomical_ephemeris_port.dart';
import 'astronomical_fact_certainty.dart';
import 'astronomical_provenance.dart';
import 'birth_timezone_database.dart';
import 'longitude_math.dart';
import 'natal_angle.dart';
import 'natal_aspect_engine.dart';
import 'natal_balance.dart';
import 'natal_body.dart';
import 'natal_calculation_metadata.dart';
import 'natal_chart_evidence.dart';
import 'natal_house_system.dart';
import 'natal_placement.dart';
import 'retrograde_detector.dart';
import 'whole_sign_houses.dart';

abstract final class FullNatalEvidenceBuilder {
  FullNatalEvidenceBuilder._();

  static NatalChartEvidence build({
    required AstronomicalEphemerisPort ephemeris,
    required DateTime utc,
    required double latitude,
    required double longitude,
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

    final angles = AngleCalculator.compute(
      ephemeris: ephemeris,
      utc: utc,
      latitudeDeg: latitude,
      longitudeDeg: longitude,
    );
    final ascSign = LongitudeMath.signOf(angles.ascendant);
    final houses = WholeSignHouses.build(
      ascendantSign: ascSign,
      provenance: provenance,
    );

    final placements = <NatalPlacement>[
      for (final body in NatalBody.values)
        _placement(
          ephemeris: ephemeris,
          body: body,
          utc: utc,
          ascSign: ascSign,
          provenance: provenance,
        ),
    ];

    final asc = NatalAngle(
      kind: NatalAngleKind.ascendant,
      sign: ascSign,
      longitude: angles.ascendant,
      degreeWithinSign: LongitudeMath.degreeWithinSign(angles.ascendant),
      house: 1,
      certainty: AstronomicalFactCertainty.exact,
      provenance: provenance,
    );
    final mcLon = angles.midheaven;
    final mcSign = LongitudeMath.signOf(mcLon);
    final mc = NatalAngle(
      kind: NatalAngleKind.midheaven,
      sign: mcSign,
      longitude: mcLon,
      degreeWithinSign: LongitudeMath.degreeWithinSign(mcLon),
      house: WholeSignHouses.houseOf(bodySign: mcSign, ascendantSign: ascSign),
      certainty: AstronomicalFactCertainty.exact,
      provenance: provenance,
    );

    final balance = NatalBalance.fromPlacements(placements);
    final aspects = NatalAspectEngine.compute(
      placements: placements,
      provenance: provenance,
    );

    return NatalChartEvidence(
      fidelity: ChartCalculationFidelity.fullNatalEphemeris,
      metadata: NatalCalculationMetadata(
        calculationVersion: AstronomicalProvenance.calcYildiznameNatalV1,
        engineId: ephemeris.engineId,
        engineVersion: ephemeris.engineVersion,
        evidenceFingerprint: fingerprint,
        houseSystem: NatalHouseSystem.wholeSign,
        zodiacSystem: AstronomicalProvenance.zodiacTropical,
        coordinateConvention: AstronomicalProvenance.coordApparentEclipticOfDate,
        timezoneDatabase: BirthTimezoneDatabase.label,
        utcInstantIso: utc.toUtc().toIso8601String(),
        birthInstantKind: 'exact',
      ),
      placements: placements,
      ascendant: asc,
      midheaven: mc,
      houses: houses,
      aspects: aspects,
      elementBalance: balance.elements,
      modalityBalance: balance.modalities,
    );
  }

  static NatalPlacement _placement({
    required AstronomicalEphemerisPort ephemeris,
    required NatalBody body,
    required DateTime utc,
    required ZodiacSignId ascSign,
    required AstronomicalProvenance provenance,
  }) {
    final lon = ephemeris.longitude(body, utc);
    final sign = LongitudeMath.signOf(lon);
    return NatalPlacement(
      body: body,
      sign: sign,
      longitude: lon,
      degreeWithinSign: LongitudeMath.degreeWithinSign(lon),
      retrograde: RetrogradeDetector.isRetrograde(
        ephemeris: ephemeris,
        body: body,
        utc: utc,
      ),
      house: WholeSignHouses.houseOf(bodySign: sign, ascendantSign: ascSign),
      certainty: AstronomicalFactCertainty.exact,
      provenance: provenance,
    );
  }
}
