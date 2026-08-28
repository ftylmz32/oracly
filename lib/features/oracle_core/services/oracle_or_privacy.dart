/// Feature-level allowlist for OR context - opt-out when prefs exist.
library;

/// Sources that may feed Oracle Core observations into OR.
abstract final class OracleOrPrivacy {
  OracleOrPrivacy._();

  static const defaultAllowed = <String>{
    'tarot',
    'coffee',
    'palm',
    'dream',
    'astrology',
    'starMap',
    'star',
    'star_map',
    'daily',
    'dailyMessage',
    'reflection',
  };

  /// When [allowed] is null, defaults apply. Empty set blocks everything.
  static Set<String> resolve(Set<String>? allowed) {
    if (allowed == null) return defaultAllowed;
    return {
      for (final s in allowed)
        if (defaultAllowed.contains(s)) s,
    };
  }

  static bool allows(String source, Set<String>? allowed) =>
      resolve(allowed).contains(source);
}
