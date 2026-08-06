/// OR-1140 — Daily energy reading domain model.
library;

import '../core/oracle_engine_type.dart';

class EnergyReading {
  const EnergyReading({
    required this.id,
    required this.date,
    required this.features,
    required this.vibrationScore,
    this.moonPhaseLabel,
    this.element,
    this.luckyColor,
    this.luckyNumber,
    this.luckyCrystal,
    this.spiritMessageKey,
  });

  final String id;
  final DateTime date;
  final Set<EnergyFeature> features;
  final double vibrationScore;
  final String? moonPhaseLabel;
  final String? element;
  final String? luckyColor;
  final int? luckyNumber;
  final String? luckyCrystal;
  final String? spiritMessageKey;

  Map<String, dynamic> toFacts() => {
        'id': id,
        'date': date.toIso8601String(),
        'features': features.map((f) => f.name).toList(),
        'vibrationScore': vibrationScore,
        'moonPhaseLabel': moonPhaseLabel,
        'element': element,
        'luckyColor': luckyColor,
        'luckyNumber': luckyNumber,
        'luckyCrystal': luckyCrystal,
        'spiritMessageKey': spiritMessageKey,
      };
}
