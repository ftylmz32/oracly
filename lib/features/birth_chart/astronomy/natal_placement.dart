/// Phase 4 — structured placement (nullable longitude for interval facts).
library;

import '../models/zodiac_sign_id.dart';
import 'astronomical_fact_certainty.dart';
import 'astronomical_provenance.dart';
import 'natal_body.dart';

class NatalPlacement {
  const NatalPlacement({
    required this.body,
    required this.certainty,
    required this.provenance,
    this.sign,
    this.longitude,
    this.degreeWithinSign,
    this.retrograde,
    this.house,
  });

  final NatalBody body;

  /// Null when certainty is ambiguous / unavailable (never invent a sign).
  final ZodiacSignId? sign;
  final double? longitude;
  final double? degreeWithinSign;
  final bool? retrograde;
  final int? house;
  final AstronomicalFactCertainty certainty;
  final AstronomicalProvenance provenance;

  Map<String, dynamic> toJson() => {
        'body': body.name,
        'certainty': certainty.name,
        'provenance': provenance.toJson(),
        if (sign != null) 'sign': sign!.name,
        if (longitude != null) 'longitude': longitude,
        if (degreeWithinSign != null) 'degreeWithinSign': degreeWithinSign,
        if (retrograde != null) 'retrograde': retrograde,
        if (house != null) 'house': house,
      };

  factory NatalPlacement.fromJson(Map<String, dynamic> json) {
    return NatalPlacement(
      body: NatalBody.values.byName(json['body'] as String),
      sign: json['sign'] != null
          ? ZodiacSignId.values.byName(json['sign'] as String)
          : null,
      certainty: AstronomicalFactCertainty.values.byName(
        json['certainty'] as String,
      ),
      provenance: AstronomicalProvenance.fromJson(
        json['provenance'] as Map<String, dynamic>,
      ),
      longitude: (json['longitude'] as num?)?.toDouble(),
      degreeWithinSign: (json['degreeWithinSign'] as num?)?.toDouble(),
      retrograde: json['retrograde'] as bool?,
      house: json['house'] as int?,
    );
  }
}
