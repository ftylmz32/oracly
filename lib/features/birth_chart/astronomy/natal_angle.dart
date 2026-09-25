/// Phase 4 — Ascendant / Midheaven structured angles.
library;

import '../models/zodiac_sign_id.dart';
import 'astronomical_fact_certainty.dart';
import 'astronomical_provenance.dart';
import 'natal_body.dart';

class NatalAngle {
  const NatalAngle({
    required this.kind,
    required this.sign,
    required this.longitude,
    required this.degreeWithinSign,
    required this.certainty,
    required this.provenance,
    this.house,
  });

  final NatalAngleKind kind;
  final ZodiacSignId sign;
  final double longitude;
  final double degreeWithinSign;
  final int? house;
  final AstronomicalFactCertainty certainty;
  final AstronomicalProvenance provenance;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'sign': sign.name,
        'longitude': longitude,
        'degreeWithinSign': degreeWithinSign,
        'certainty': certainty.name,
        'provenance': provenance.toJson(),
        if (house != null) 'house': house,
      };

  factory NatalAngle.fromJson(Map<String, dynamic> json) {
    return NatalAngle(
      kind: NatalAngleKind.values.byName(json['kind'] as String),
      sign: ZodiacSignId.values.byName(json['sign'] as String),
      longitude: (json['longitude'] as num).toDouble(),
      degreeWithinSign: (json['degreeWithinSign'] as num).toDouble(),
      certainty: AstronomicalFactCertainty.values.byName(
        json['certainty'] as String,
      ),
      provenance: AstronomicalProvenance.fromJson(
        json['provenance'] as Map<String, dynamic>,
      ),
      house: json['house'] as int?,
    );
  }
}
