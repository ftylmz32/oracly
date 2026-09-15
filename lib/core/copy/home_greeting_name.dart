/// Safe first-name extraction for the Home greeting. Never invents a name,
/// never exposes a full multi-word name (which overflows the hero's
/// single-line width and gets ellipsis-truncated), and never surfaces a
/// placeholder/null-like value as if it were a real name.
library;

abstract final class HomeGreetingName {
  HomeGreetingName._();

  static const _placeholders = {
    'null',
    'user',
    'guest',
    'undefined',
    'n/a',
    'na',
    '-',
    '—',
  };

  /// Returns a trustworthy first name, or null when none is available.
  /// Callers must render a bare (name-less) greeting on null — never a
  /// generic stand-in word.
  static String? firstNameOrNull(String? raw) {
    if (raw == null) return null;
    // Collapse repeated/mixed whitespace, then trim ends.
    final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) return null;
    if (collapsed.contains('@')) return null; // never an email/prefix
    final firstToken = collapsed.split(' ').first;
    if (firstToken.isEmpty) return null;
    if (_placeholders.contains(firstToken.toLowerCase())) return null;
    return firstToken;
  }
}
