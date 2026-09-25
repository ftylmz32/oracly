/// Full E4 fake evidence — angles, houses, aspects.
library;

import 'package:oracly_new/features/birth_chart/astronomy/astronomical_fact_certainty.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_angle.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_aspect.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_body.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_chart_evidence.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_house.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_house_system.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';
import 'package:oracly_new/features/birth_chart/models/element_balance.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';

import 'narrative_fixture_support.dart';

abstract final class NarrativeEvidenceFull {
  NarrativeEvidenceFull._();

  static NatalChartEvidence build() {
    return NatalChartEvidence(
      fidelity: ChartCalculationFidelity.fullNatalEphemeris,
      metadata: narrativeTestMeta,
      placements: [
        narrativePlacement(
          body: NatalBody.sun,
          sign: ZodiacSignId.taurus,
          certainty: AstronomicalFactCertainty.exact,
          degree: 24.5,
          retro: false,
          house: 10,
          lon: 54.5,
        ),
        narrativePlacement(
          body: NatalBody.moon,
          sign: ZodiacSignId.scorpio,
          certainty: AstronomicalFactCertainty.exact,
          degree: 12.0,
          retro: false,
          house: 4,
        ),
        narrativePlacement(
          body: NatalBody.mercury,
          sign: ZodiacSignId.aries,
          certainty: AstronomicalFactCertainty.exact,
          degree: 8.0,
          retro: false,
          house: 9,
        ),
        narrativePlacement(
          body: NatalBody.venus,
          sign: ZodiacSignId.gemini,
          certainty: AstronomicalFactCertainty.exact,
          degree: 3.0,
          retro: false,
          house: 11,
        ),
        narrativePlacement(
          body: NatalBody.mars,
          sign: ZodiacSignId.leo,
          certainty: AstronomicalFactCertainty.exact,
          degree: 18.0,
          retro: false,
          house: 1,
        ),
        narrativePlacement(
          body: NatalBody.jupiter,
          sign: ZodiacSignId.cancer,
          certainty: AstronomicalFactCertainty.exact,
          degree: 5.0,
          retro: false,
          house: 12,
        ),
        narrativePlacement(
          body: NatalBody.saturn,
          sign: ZodiacSignId.capricorn,
          certainty: AstronomicalFactCertainty.exact,
          degree: 14.0,
          retro: true,
          house: 6,
        ),
      ],
      ascendant: NatalAngle(
        kind: NatalAngleKind.ascendant,
        sign: ZodiacSignId.virgo,
        longitude: 150.0,
        degreeWithinSign: 0.0,
        certainty: AstronomicalFactCertainty.exact,
        provenance: narrativeTestProvenance,
        house: 1,
      ),
      midheaven: NatalAngle(
        kind: NatalAngleKind.midheaven,
        sign: ZodiacSignId.gemini,
        longitude: 60.0,
        degreeWithinSign: 0.0,
        certainty: AstronomicalFactCertainty.exact,
        provenance: narrativeTestProvenance,
        house: 10,
      ),
      houses: [
        for (var i = 1; i <= 12; i++)
          NatalHouse(
            number: i,
            sign: ZodiacSignId.values[(i + 4) % 12],
            cuspLongitude: ((i + 4) % 12) * 30.0,
            system: NatalHouseSystem.wholeSign,
            certainty: AstronomicalFactCertainty.exact,
            provenance: narrativeTestProvenance,
          ),
      ],
      aspects: [
        NatalAspect(
          bodyA: NatalBody.sun,
          bodyB: NatalBody.moon,
          type: AspectType.opposition,
          orb: 2.1,
          certainty: AstronomicalFactCertainty.exact,
          provenance: narrativeTestProvenance,
        ),
        NatalAspect(
          bodyA: NatalBody.venus,
          bodyB: NatalBody.mars,
          type: AspectType.sextile,
          orb: 1.0,
          certainty: AstronomicalFactCertainty.exact,
          provenance: narrativeTestProvenance,
        ),
      ],
      elementBalance:
          const ElementBalance(fire: 2, earth: 2, air: 1, water: 2),
      modalityBalance: const {
        ChartModality.cardinal: 2,
        ChartModality.fixed: 3,
        ChartModality.mutable: 2,
      },
    );
  }
}
