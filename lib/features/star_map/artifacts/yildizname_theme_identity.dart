/// Local-only historical theme identity (NOT provider themeRef).
///
/// Provider refs (`theme.0`…) are request-local. Cross-artifact recurrence
/// uses a label-derived canonical key (`yth_<16 hex>`). Never send keys to
/// the provider.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

abstract final class YildiznameThemeIdentity {
  YildiznameThemeIdentity._();

  /// Conservative normalize: trim, collapse whitespace, Unicode lower-case.
  /// No ASCII transliteration / fuzzy synonym merge.
  /// Turkish I/ı/İ may remain distinct under Unicode default casing (OK).
  static String normalize(String raw) {
    final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.isEmpty) return '';
    return collapsed.toLowerCase();
  }

  /// Local history identity: `yth_` + first 16 hex of SHA-256(normalized).
  static String keyFor(String label) {
    final n = normalize(label);
    if (n.isEmpty) return '';
    final digest = sha256.convert(utf8.encode(n));
    final hex = digest.toString();
    return 'yth_${hex.substring(0, 16)}';
  }

  static bool sameLabel(String a, String b) =>
      normalize(a).isNotEmpty && normalize(a) == normalize(b);
}
