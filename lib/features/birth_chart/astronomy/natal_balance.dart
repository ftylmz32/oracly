/// Phase 4 — element / modality balance from exact planetary signs.
library;

import '../models/element_balance.dart';
import '../models/zodiac_sign_id.dart';
import 'astronomical_fact_certainty.dart';
import 'natal_body.dart';
import 'natal_placement.dart';

class NatalBalanceResult {
  const NatalBalanceResult({
    required this.elements,
    required this.modalities,
    required this.primaryElement,
    required this.primaryModality,
  });

  final ElementBalance elements;
  final Map<ChartModality, int> modalities;
  final ChartElement primaryElement;
  final ChartModality primaryModality;
}

abstract final class NatalBalance {
  NatalBalance._();

  /// Tie-break order for elements: fire > earth > air > water.
  /// Tie-break for modalities: cardinal > fixed > mutable.
  static NatalBalanceResult fromPlacements(List<NatalPlacement> placements) {
    var fire = 0, earth = 0, air = 0, water = 0;
    final mod = {
      ChartModality.cardinal: 0,
      ChartModality.fixed: 0,
      ChartModality.mutable: 0,
    };
    for (final p in placements) {
      if (!natalBalanceBodies.contains(p.body)) continue;
      if (p.certainty != AstronomicalFactCertainty.exact &&
          p.certainty != AstronomicalFactCertainty.intervalStable) {
        continue;
      }
      final sign = p.sign;
      if (sign == null) continue;
      switch (_element(sign)) {
        case ChartElement.fire:
          fire++;
        case ChartElement.earth:
          earth++;
        case ChartElement.air:
          air++;
        case ChartElement.water:
          water++;
      }
      mod[_modality(sign)] = mod[_modality(sign)]! + 1;
    }
    final elements = ElementBalance(fire: fire, earth: earth, air: air, water: water);
    return NatalBalanceResult(
      elements: elements,
      modalities: mod,
      primaryElement: _pickElement(fire, earth, air, water),
      primaryModality: _pickModality(mod),
    );
  }

  static ChartElement _element(ZodiacSignId s) => switch (s) {
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
        _ => ChartElement.water,
      };

  static ChartModality _modality(ZodiacSignId s) => switch (s) {
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
        _ => ChartModality.mutable,
      };

  static ChartElement _pickElement(int f, int e, int a, int w) {
    final scores = [
      (ChartElement.fire, f),
      (ChartElement.earth, e),
      (ChartElement.air, a),
      (ChartElement.water, w),
    ]..sort((x, y) => y.$2.compareTo(x.$2));
    return scores.first.$1;
  }

  static ChartModality _pickModality(Map<ChartModality, int> m) {
    const order = [
      ChartModality.cardinal,
      ChartModality.fixed,
      ChartModality.mutable,
    ];
    var best = order.first;
    for (final cand in order.skip(1)) {
      if (m[cand]! > m[best]!) best = cand;
    }
    return best;
  }
}
