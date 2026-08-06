/// OR-1140 — Compatibility reading domain model.
library;

class CompatibilityReading {
  const CompatibilityReading({
    required this.id,
    required this.subjectA,
    required this.subjectB,
    required this.overallScore,
    required this.dimensions,
    required this.createdAt,
  });

  final String id;
  final String subjectA;
  final String subjectB;
  final double overallScore;
  final Map<String, double> dimensions;
  final DateTime createdAt;

  Map<String, dynamic> toFacts() => {
        'id': id,
        'subjectA': subjectA,
        'subjectB': subjectB,
        'overallScore': overallScore,
        'dimensions': dimensions,
      };
}
