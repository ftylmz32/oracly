/// Phase 4 — assemble BirthChart from structured natal evidence.
library;

import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import '../models/chart_fidelity.dart';
import '../models/dominant_energy.dart';
import '../models/planet.dart';
import '../models/zodiac_sign_id.dart';
import '../services/chart_insight_locale.dart';
import 'astronomical_fact_certainty.dart';
import 'natal_body.dart';
import 'natal_chart_evidence.dart';
import 'natal_presentation_adapter.dart';

abstract final class NatalChartAssembler {
  NatalChartAssembler._();

  static BirthChart reduced({
    required BirthProfile profile,
    required NatalChartEvidence evidence,
    required String id,
  }) {
    final sunSign = _sunSign(evidence) ?? ZodiacSignId.fromDate(profile.birthDate);
    return BirthChart(
      id: id,
      profile: profile,
      sun: Planet(id: PlanetId.sun, sign: sunSign, degree: 0, house: 0),
      planets: const [],
      houses: const [],
      aspects: const [],
      elementBalance: evidence.elementBalance,
      dominantEnergy: _dominant(evidence, sunSign),
      lifeThemes: const [],
      insights: const [],
      generatedAt: DateTime.now(),
      precision: ChartPrecision.partialNoTime,
      fidelity: ChartCalculationFidelity.reducedNatal,
      natalEvidence: evidence,
    );
  }

  static BirthChart full({
    required BirthProfile profile,
    required NatalChartEvidence evidence,
  }) {
    final sun = evidence.placements.firstWhere((p) => p.body == NatalBody.sun);
    final moon = evidence.placements.firstWhere((p) => p.body == NatalBody.moon);
    final rising = evidence.ascendant;
    final mc = evidence.midheaven;
    return BirthChart(
      id: 'chart_${profile.birthDate.millisecondsSinceEpoch}',
      profile: profile,
      sun: NatalPresentationAdapter.exactPlanet(sun)!,
      moon: NatalPresentationAdapter.exactPlanet(moon),
      rising: rising == null
          ? null
          : Planet(
              id: PlanetId.ascendant,
              sign: rising.sign,
              degree: rising.degreeWithinSign,
              house: 1,
            ),
      midheaven: mc == null
          ? null
          : Planet(
              id: PlanetId.midheaven,
              sign: mc.sign,
              degree: mc.degreeWithinSign,
              house: mc.house ?? 0,
            ),
      planets: NatalPresentationAdapter.planets(evidence),
      houses: NatalPresentationAdapter.houses(evidence),
      aspects: NatalPresentationAdapter.aspects(evidence),
      elementBalance: evidence.elementBalance,
      dominantEnergy: _dominant(evidence, sun.sign!),
      lifeThemes: const [],
      insights: const [],
      generatedAt: DateTime.now(),
      precision: ChartPrecision.full,
      fidelity: ChartCalculationFidelity.fullNatalEphemeris,
      natalEvidence: evidence,
    );
  }

  static ZodiacSignId? _sunSign(NatalChartEvidence e) {
    for (final p in e.placements) {
      if (p.body == NatalBody.sun &&
          p.sign != null &&
          (p.certainty == AstronomicalFactCertainty.exact ||
              p.certainty == AstronomicalFactCertainty.intervalStable)) {
        return p.sign;
      }
    }
    return null;
  }

  static DominantEnergy _dominant(
    NatalChartEvidence e,
    ZodiacSignId sunSign,
  ) {
    final bal = e.elementBalance;
    final primary = [
      (ChartElement.fire, bal.fire),
      (ChartElement.earth, bal.earth),
      (ChartElement.air, bal.air),
      (ChartElement.water, bal.water),
    ].reduce((a, b) => b.$2 > a.$2 ? b : a).$1;
    final modality = e.modalityBalance.isEmpty
        ? ChartModality.cardinal
        : e.modalityBalance.entries
            .reduce((a, b) => b.value > a.value ? b : a)
            .key;
    final elementLabel = ChartInsightLocale.elementName(primary);
    final signLabel = ChartInsightLocale.signName(sunSign);
    return DominantEnergy(
      primaryElement: primary,
      primaryModality: modality,
      label: ChartInsightLocale.fill('birth.energy.label', {
        'element': elementLabel,
      }),
      summary: ChartInsightLocale.fill('birth.energy.summary', {
        'sign': signLabel,
        'element': elementLabel,
      }),
    );
  }
}
