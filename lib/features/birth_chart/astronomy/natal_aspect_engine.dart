/// Phase 4 — major aspects among Sun–Pluto (no Asc/MC).
library;

import '../models/zodiac_sign_id.dart';
import 'astronomical_fact_certainty.dart';
import 'astronomical_provenance.dart';
import 'longitude_math.dart';
import 'natal_aspect.dart';
import 'natal_body.dart';
import 'natal_placement.dart';

abstract final class NatalAspectEngine {
  NatalAspectEngine._();

  static List<NatalAspect> compute({
    required List<NatalPlacement> placements,
    required AstronomicalProvenance provenance,
  }) {
    final byBody = {
      for (final p in placements)
        if (p.longitude != null &&
            natalAspectBodies.contains(p.body) &&
            p.certainty == AstronomicalFactCertainty.exact)
          p.body: p.longitude!,
    };
    final bodies = byBody.keys.toList();
    final out = <NatalAspect>[];
    for (var i = 0; i < bodies.length; i++) {
      for (var j = i + 1; j < bodies.length; j++) {
        final a = bodies[i];
        final b = bodies[j];
        final sep = LongitudeMath.absSeparation(byBody[a]!, byBody[b]!);
        for (final type in AspectType.values) {
          final orb = (sep - type.angle).abs();
          if (orb <= type.defaultOrb) {
            out.add(NatalAspect(
              bodyA: a,
              bodyB: b,
              type: type,
              orb: orb,
              certainty: AstronomicalFactCertainty.exact,
              provenance: provenance,
            ));
            break;
          }
        }
      }
    }
    return out;
  }
}
