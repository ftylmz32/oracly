/// Phase 4 — Whole Sign house cusp evidence.
library;

import '../models/zodiac_sign_id.dart';
import 'astronomical_fact_certainty.dart';
import 'astronomical_provenance.dart';
import 'natal_house_system.dart';

class NatalHouse {
  const NatalHouse({
    required this.number,
    required this.sign,
    required this.cuspLongitude,
    required this.system,
    required this.certainty,
    required this.provenance,
  });

  final int number;
  final ZodiacSignId sign;

  /// Whole Sign cusp = 0° of the house sign.
  final double cuspLongitude;
  final NatalHouseSystem system;
  final AstronomicalFactCertainty certainty;
  final AstronomicalProvenance provenance;

  Map<String, dynamic> toJson() => {
        'number': number,
        'sign': sign.name,
        'cuspLongitude': cuspLongitude,
        'system': system.name,
        'certainty': certainty.name,
        'provenance': provenance.toJson(),
      };

  factory NatalHouse.fromJson(Map<String, dynamic> json) {
    return NatalHouse(
      number: json['number'] as int,
      sign: ZodiacSignId.values.byName(json['sign'] as String),
      cuspLongitude: (json['cuspLongitude'] as num).toDouble(),
      system: NatalHouseSystem.values.byName(json['system'] as String),
      certainty: AstronomicalFactCertainty.values.byName(
        json['certainty'] as String,
      ),
      provenance: AstronomicalProvenance.fromJson(
        json['provenance'] as Map<String, dynamic>,
      ),
    );
  }
}
