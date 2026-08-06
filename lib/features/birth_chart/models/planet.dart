/// SPRINT-002 — Planet placement in natal chart.
library;

import 'zodiac_sign_id.dart';

class Planet {
  const Planet({
    required this.id,
    required this.sign,
    required this.degree,
    required this.house,
  });

  final PlanetId id;
  final ZodiacSignId sign;
  final double degree;
  final int house;

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'sign': sign.name,
        'degree': degree,
        'house': house,
      };

  factory Planet.fromJson(Map<String, dynamic> json) {
    return Planet(
      id: PlanetId.values.byName(json['id'] as String),
      sign: ZodiacSignId.values.byName(json['sign'] as String),
      degree: (json['degree'] as num).toDouble(),
      house: json['house'] as int,
    );
  }
}
