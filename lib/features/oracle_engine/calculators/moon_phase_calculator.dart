/// OR-1140 — Moon phase structural calculator.
library;

enum MoonPhaseKind {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

abstract class MoonPhaseCalculator {
  MoonPhaseKind phaseFor(DateTime date);
  String labelKeyFor(MoonPhaseKind phase);
}

class AstronomicalMoonPhaseCalculator implements MoonPhaseCalculator {
  @override
  MoonPhaseKind phaseFor(DateTime date) {
    final synodicMonth = 29.530588853;
    final knownNewMoon = DateTime.utc(2000, 1, 6, 18, 14);
    final days = date.toUtc().difference(knownNewMoon).inHours / 24.0;
    final phase = (days / synodicMonth) % 1.0;

    if (phase < 0.0625) return MoonPhaseKind.newMoon;
    if (phase < 0.1875) return MoonPhaseKind.waxingCrescent;
    if (phase < 0.3125) return MoonPhaseKind.firstQuarter;
    if (phase < 0.4375) return MoonPhaseKind.waxingGibbous;
    if (phase < 0.5625) return MoonPhaseKind.fullMoon;
    if (phase < 0.6875) return MoonPhaseKind.waningGibbous;
    if (phase < 0.8125) return MoonPhaseKind.lastQuarter;
    return MoonPhaseKind.waningCrescent;
  }

  @override
  String labelKeyFor(MoonPhaseKind phase) => 'moon.phase.${phase.name}';
}
