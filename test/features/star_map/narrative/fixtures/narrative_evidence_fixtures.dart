/// Fake NatalChartEvidence builders — no real ephemeris.
library;

import 'package:oracly_new/features/birth_chart/astronomy/astronomical_fact_certainty.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_body.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_chart_evidence.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';
import 'package:oracly_new/features/birth_chart/models/element_balance.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';

import 'narrative_evidence_full.dart';
import 'narrative_fixture_support.dart';

abstract final class NarrativeEvidenceFixtures {
  NarrativeEvidenceFixtures._();

  static NatalChartEvidence legacySun() => NatalChartEvidence(
        fidelity: ChartCalculationFidelity.tropicalSunSign,
        metadata: narrativeTestMeta,
        placements: [
          narrativePlacement(
            body: NatalBody.sun,
            sign: ZodiacSignId.taurus,
            certainty: AstronomicalFactCertainty.exact,
            degree: 0,
            house: 0,
            lon: 45,
          ),
        ],
        houses: const [],
        aspects: const [],
        elementBalance:
            const ElementBalance(fire: 1, earth: 0, air: 0, water: 0),
        modalityBalance: const {ChartModality.fixed: 1},
      );

  static NatalChartEvidence reducedStable() => NatalChartEvidence(
        fidelity: ChartCalculationFidelity.reducedNatal,
        metadata: narrativeTestMeta,
        placements: [
          narrativePlacement(
            body: NatalBody.sun,
            sign: ZodiacSignId.taurus,
            certainty: AstronomicalFactCertainty.intervalStable,
          ),
          narrativePlacement(
            body: NatalBody.moon,
            sign: ZodiacSignId.scorpio,
            certainty: AstronomicalFactCertainty.intervalStable,
          ),
          narrativePlacement(
            body: NatalBody.mercury,
            sign: ZodiacSignId.aries,
            certainty: AstronomicalFactCertainty.intervalStable,
          ),
        ],
        houses: const [],
        aspects: const [],
        elementBalance:
            const ElementBalance(fire: 1, earth: 1, air: 0, water: 1),
        modalityBalance: const {
          ChartModality.fixed: 2,
          ChartModality.cardinal: 1,
        },
      );

  static NatalChartEvidence reducedAmbiguousMoon() => NatalChartEvidence(
        fidelity: ChartCalculationFidelity.reducedNatal,
        metadata: narrativeTestMeta,
        placements: [
          narrativePlacement(
            body: NatalBody.sun,
            sign: ZodiacSignId.taurus,
            certainty: AstronomicalFactCertainty.intervalStable,
          ),
          narrativePlacement(
            body: NatalBody.moon,
            sign: null,
            certainty: AstronomicalFactCertainty.ambiguous,
          ),
        ],
        houses: const [],
        aspects: const [],
        elementBalance:
            const ElementBalance(fire: 0, earth: 1, air: 0, water: 0),
        modalityBalance: const {ChartModality.fixed: 1},
      );

  static NatalChartEvidence fullNatal() => NarrativeEvidenceFull.build();
}
