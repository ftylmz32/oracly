/// Build placement / angle / house / aspect facts from NatalChartEvidence.
library;

import '../../../birth_chart/astronomy/astronomical_fact_certainty.dart';
import '../../../birth_chart/astronomy/natal_chart_evidence.dart';
import '../../../birth_chart/astronomy/natal_placement.dart';
import '../../../birth_chart/models/chart_fidelity.dart';
import 'yildizname_angle_fact.dart';
import 'yildizname_aspect_fact.dart';
import 'yildizname_house_fact.dart';
import 'yildizname_narrative_scope.dart';
import 'yildizname_placement_fact.dart';

abstract final class YildiznameRequestFactBuilder {
  YildiznameRequestFactBuilder._();

  static List<YildiznamePlacementFact> placements(
    NatalChartEvidence evidence,
    YildiznameNarrativeScope scope,
  ) {
    final out = <YildiznamePlacementFact>[];
    for (final p in evidence.placements) {
      final fact = _placement(p, scope, evidence.fidelity);
      if (fact != null) out.add(fact);
    }
    return out;
  }

  static YildiznamePlacementFact? _placement(
    NatalPlacement p,
    YildiznameNarrativeScope scope,
    ChartCalculationFidelity fidelity,
  ) {
    if (p.sign == null) return null;
    if (p.certainty == AstronomicalFactCertainty.ambiguous ||
        p.certainty == AstronomicalFactCertainty.unavailable ||
        p.certainty == AstronomicalFactCertainty.unsupported) {
      return null;
    }
    final ref = 'placement.${p.body.name}';
    if (scope == YildiznameNarrativeScope.legacy) {
      if (p.body.name != 'sun') return null;
      return YildiznamePlacementFact(
        factRef: ref,
        body: p.body.name,
        sign: p.sign!.name,
        certainty: p.certainty.name,
      );
    }
    if (scope == YildiznameNarrativeScope.reduced) {
      if (p.certainty != AstronomicalFactCertainty.intervalStable) return null;
      return YildiznamePlacementFact(
        factRef: ref,
        body: p.body.name,
        sign: p.sign!.name,
        certainty: p.certainty.name,
      );
    }
    return YildiznamePlacementFact(
      factRef: ref,
      body: p.body.name,
      sign: p.sign!.name,
      certainty: p.certainty.name,
      degreeWithinSign: p.degreeWithinSign,
      retrograde: p.retrograde,
      house: p.house,
    );
  }

  static List<YildiznameAngleFact> angles(
    NatalChartEvidence evidence,
    YildiznameNarrativeScope scope,
  ) {
    if (scope != YildiznameNarrativeScope.full) return const [];
    final out = <YildiznameAngleFact>[];
    final asc = evidence.ascendant;
    if (asc != null) {
      out.add(YildiznameAngleFact(
        factRef: 'angle.ascendant',
        kind: asc.kind.name,
        sign: asc.sign.name,
        certainty: asc.certainty.name,
        degreeWithinSign: asc.degreeWithinSign,
        house: asc.house,
      ));
    }
    final mc = evidence.midheaven;
    if (mc != null) {
      out.add(YildiznameAngleFact(
        factRef: 'angle.midheaven',
        kind: mc.kind.name,
        sign: mc.sign.name,
        certainty: mc.certainty.name,
        degreeWithinSign: mc.degreeWithinSign,
        house: mc.house,
      ));
    }
    return out;
  }

  static List<YildiznameHouseFact> houses(
    NatalChartEvidence evidence,
    YildiznameNarrativeScope scope,
  ) {
    if (scope != YildiznameNarrativeScope.full) return const [];
    return [
      for (final h in evidence.houses)
        YildiznameHouseFact(
          factRef: 'house.${h.number}',
          number: h.number,
          sign: h.sign.name,
        ),
    ];
  }

  static List<YildiznameAspectFact> aspects(
    NatalChartEvidence evidence,
    YildiznameNarrativeScope scope,
  ) {
    if (scope != YildiznameNarrativeScope.full) return const [];
    return [
      for (final a in evidence.aspects)
        YildiznameAspectFact(
          factRef: 'aspect.${a.bodyA.name}.${a.bodyB.name}.${a.type.name}',
          bodyA: a.bodyA.name,
          bodyB: a.bodyB.name,
          type: a.type.name,
          orb: a.orb,
        ),
    ];
  }
}
