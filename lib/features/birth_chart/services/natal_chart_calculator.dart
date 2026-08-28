/// Default chart calculator — tropical sun sign until a real ephemeris is wired.
library;

import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import '../models/dominant_energy.dart';
import '../models/element_balance.dart';
import '../models/planet.dart';
import '../models/zodiac_sign_id.dart';
import 'chart_calculation_port.dart';
import 'chart_insight_locale.dart';

class NatalChartCalculator implements ChartCalculationPort {
  const NatalChartCalculator();

  @override
  ChartCalculationFidelity get fidelity =>
      ChartCalculationFidelity.tropicalSunSign;

  @override
  BirthChart calculate(BirthProfile profile) {
    final sunSign = ZodiacSignId.fromDate(profile.birthDate);
    final element = _elementOf(sunSign);
    final modality = _modalityOf(sunSign);
    final elementLabel = ChartInsightLocale.elementName(element);
    final signLabel = ChartInsightLocale.signName(sunSign);

    return BirthChart(
      id: 'chart_${profile.birthDate.millisecondsSinceEpoch}',
      profile: profile,
      sun: Planet(id: PlanetId.sun, sign: sunSign, degree: 0, house: 0),
      planets: const [],
      houses: const [],
      aspects: const [],
      elementBalance: _balance(element),
      dominantEnergy: DominantEnergy(
        primaryElement: element,
        primaryModality: modality,
        label: ChartInsightLocale.fill('birth.energy.label', {
          'element': elementLabel,
        }),
        summary: ChartInsightLocale.fill('birth.energy.summary', {
          'sign': signLabel,
          'element': elementLabel,
        }),
      ),
      lifeThemes: const [],
      insights: const [],
      generatedAt: DateTime.now(),
      precision: ChartPrecision.partialNoTime,
      fidelity: fidelity,
    );
  }

  ElementBalance _balance(ChartElement element) {
    return ElementBalance(
      fire: element == ChartElement.fire ? 1 : 0,
      earth: element == ChartElement.earth ? 1 : 0,
      air: element == ChartElement.air ? 1 : 0,
      water: element == ChartElement.water ? 1 : 0,
    );
  }

  ChartElement _elementOf(ZodiacSignId sign) {
    return switch (sign) {
      ZodiacSignId.aries ||
      ZodiacSignId.leo ||
      ZodiacSignId.sagittarius =>
        ChartElement.fire,
      ZodiacSignId.taurus ||
      ZodiacSignId.virgo ||
      ZodiacSignId.capricorn =>
        ChartElement.earth,
      ZodiacSignId.gemini ||
      ZodiacSignId.libra ||
      ZodiacSignId.aquarius =>
        ChartElement.air,
      ZodiacSignId.cancer ||
      ZodiacSignId.scorpio ||
      ZodiacSignId.pisces =>
        ChartElement.water,
    };
  }

  ChartModality _modalityOf(ZodiacSignId sign) {
    return switch (sign) {
      ZodiacSignId.aries ||
      ZodiacSignId.cancer ||
      ZodiacSignId.libra ||
      ZodiacSignId.capricorn =>
        ChartModality.cardinal,
      ZodiacSignId.taurus ||
      ZodiacSignId.leo ||
      ZodiacSignId.scorpio ||
      ZodiacSignId.aquarius =>
        ChartModality.fixed,
      ZodiacSignId.gemini ||
      ZodiacSignId.virgo ||
      ZodiacSignId.sagittarius ||
      ZodiacSignId.pisces =>
        ChartModality.mutable,
    };
  }
}
