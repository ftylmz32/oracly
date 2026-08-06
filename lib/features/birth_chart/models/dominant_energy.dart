/// SPRINT-002 — Dominant chart energy signature.
library;

import 'zodiac_sign_id.dart';

class DominantEnergy {
  const DominantEnergy({
    required this.primaryElement,
    required this.primaryModality,
    required this.label,
    required this.summary,
  });

  final ChartElement primaryElement;
  final ChartModality primaryModality;
  final String label;
  final String summary;

  Map<String, dynamic> toJson() => {
        'primaryElement': primaryElement.name,
        'primaryModality': primaryModality.name,
        'label': label,
        'summary': summary,
      };

  factory DominantEnergy.fromJson(Map<String, dynamic> json) {
    return DominantEnergy(
      primaryElement:
          ChartElement.values.byName(json['primaryElement'] as String),
      primaryModality:
          ChartModality.values.byName(json['primaryModality'] as String),
      label: json['label'] as String,
      summary: json['summary'] as String,
    );
  }
}
