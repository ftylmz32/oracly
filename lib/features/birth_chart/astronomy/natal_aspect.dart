/// Phase 4 — major aspect between natal bodies.
library;

import '../models/zodiac_sign_id.dart';
import 'astronomical_fact_certainty.dart';
import 'astronomical_provenance.dart';
import 'natal_body.dart';

class NatalAspect {
  const NatalAspect({
    required this.bodyA,
    required this.bodyB,
    required this.type,
    required this.orb,
    required this.certainty,
    required this.provenance,
  });

  final NatalBody bodyA;
  final NatalBody bodyB;
  final AspectType type;
  final double orb;
  final AstronomicalFactCertainty certainty;
  final AstronomicalProvenance provenance;

  Map<String, dynamic> toJson() => {
        'bodyA': bodyA.name,
        'bodyB': bodyB.name,
        'type': type.name,
        'orb': orb,
        'certainty': certainty.name,
        'provenance': provenance.toJson(),
      };

  factory NatalAspect.fromJson(Map<String, dynamic> json) {
    return NatalAspect(
      bodyA: NatalBody.values.byName(json['bodyA'] as String),
      bodyB: NatalBody.values.byName(json['bodyB'] as String),
      type: AspectType.values.byName(json['type'] as String),
      orb: (json['orb'] as num).toDouble(),
      certainty: AstronomicalFactCertainty.values.byName(
        json['certainty'] as String,
      ),
      provenance: AstronomicalProvenance.fromJson(
        json['provenance'] as Map<String, dynamic>,
      ),
    );
  }
}
