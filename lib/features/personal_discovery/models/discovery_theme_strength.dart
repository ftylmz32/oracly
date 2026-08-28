/// How often a theme appears across real discoveries.
library;

enum DiscoveryThemeStrength {
  /// Seen in exactly one discovery record.
  observed,

  /// Seen in two or more independent discoveries.
  recurring,

  /// Seen across multiple modalities with solid recurrence.
  strong,
}
