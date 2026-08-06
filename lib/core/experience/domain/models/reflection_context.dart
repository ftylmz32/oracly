/// RC-011 — Reflection style recommendation.
library;

enum ReflectionStyle {
  gentle,
  observational,
  deepening,
  quiet,
  invitation,
}

class ReflectionContext {
  const ReflectionContext({
    required this.style,
    required this.surfacePersonalInsights,
    required this.preferShortForm,
    this.leadingThemeId,
  });

  final ReflectionStyle style;
  final bool surfacePersonalInsights;
  final bool preferShortForm;
  final String? leadingThemeId;
}
