/// Deterministic variant pick — same subject keeps the same bucket.
library;

abstract final class ExperimentAssigner {
  ExperimentAssigner._();

  static String pick({
    required String subjectId,
    required String experimentId,
    required int version,
    required List<String> variants,
  }) {
    if (variants.isEmpty) return 'control';
    if (variants.length == 1) return variants.first;
    final index = _hash('$subjectId|$experimentId|$version') % variants.length;
    return variants[index];
  }

  static int _hash(String input) => input.hashCode.abs();
}
