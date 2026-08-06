/// OR-1140 — Compatibility dimension score calculator.
library;

abstract class CompatibilityCalculator {
  Map<String, double> dimensionsFor({
    required String subjectA,
    required String subjectB,
    Map<String, dynamic>? chartA,
    Map<String, dynamic>? chartB,
  });

  double overallScore(Map<String, double> dimensions);
}

class WeightedCompatibilityCalculator implements CompatibilityCalculator {
  @override
  Map<String, double> dimensionsFor({
    required String subjectA,
    required String subjectB,
    Map<String, dynamic>? chartA,
    Map<String, dynamic>? chartB,
  }) {
    final seed = subjectA.hashCode ^ subjectB.hashCode;
    double dim(int offset) => ((seed + offset).abs() % 100) / 100.0;

    return {
      'emotional': dim(1),
      'intellectual': dim(2),
      'physical': dim(3),
      'spiritual': dim(4),
      'communication': dim(5),
    };
  }

  @override
  double overallScore(Map<String, double> dimensions) {
    if (dimensions.isEmpty) return 0;
    return dimensions.values.reduce((a, b) => a + b) / dimensions.length;
  }
}
