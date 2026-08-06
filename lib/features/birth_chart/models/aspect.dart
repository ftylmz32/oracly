/// SPRINT-002 — Planetary aspect.
library;

import 'zodiac_sign_id.dart';

class Aspect {
  const Aspect({
    required this.planetA,
    required this.planetB,
    required this.type,
    required this.orb,
  });

  final PlanetId planetA;
  final PlanetId planetB;
  final AspectType type;
  final double orb;

  Map<String, dynamic> toJson() => {
        'planetA': planetA.name,
        'planetB': planetB.name,
        'type': type.name,
        'orb': orb,
      };

  factory Aspect.fromJson(Map<String, dynamic> json) {
    return Aspect(
      planetA: PlanetId.values.byName(json['planetA'] as String),
      planetB: PlanetId.values.byName(json['planetB'] as String),
      type: AspectType.values.byName(json['type'] as String),
      orb: (json['orb'] as num).toDouble(),
    );
  }
}
