/// SPRINT-002 — Astrological house in natal chart.
library;

import 'zodiac_sign_id.dart';

class House {
  const House({
    required this.number,
    required this.sign,
    required this.cuspDegree,
  });

  final int number;
  final ZodiacSignId sign;
  final double cuspDegree;

  Map<String, dynamic> toJson() => {
        'number': number,
        'sign': sign.name,
        'cuspDegree': cuspDegree,
      };

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      number: json['number'] as int,
      sign: ZodiacSignId.values.byName(json['sign'] as String),
      cuspDegree: (json['cuspDegree'] as num).toDouble(),
    );
  }
}
