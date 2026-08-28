/// Thin ThemeEvidence projection for OR - never a parallel store.
library;

class OracleThemeEvidence {
  const OracleThemeEvidence({
    required this.evidenceId,
    required this.theme,
    required this.sourceFeature,
    required this.observedAt,
  });

  final String evidenceId;
  final String theme;
  final String sourceFeature;
  final DateTime observedAt;
}
