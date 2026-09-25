/// Typed Yıldızname Narrative result failures.
library;

enum YildiznameResultErrorKind {
  schema,
  version,
  locale,
  scope,
  bounds,
  duplicate,
  unknownKey,
  unknownKind,
  factRef,
  themeRef,
  scopeHonesty,
  grounding,
  privacy,
  safety,
  prose,
  coverage,
  genericity,
  synthesis,
  quality,
}

final class YildiznameResultException implements Exception {
  YildiznameResultException(this.kind, [this.message = '']);

  final YildiznameResultErrorKind kind;
  final String message;

  @override
  String toString() => 'YildiznameResultException($kind: $message)';
}
