/// The name a Yıldızname reading may address the person by.
///
/// Mirrors backend `sanitizeYildiznameAddressName`: letters only (with
/// apostrophe, hyphen, period and one inner space), at most two words and
/// [kYildiznameMaxAddressNameChars]. Anything else is dropped, never sent.
library;

import '../versions.dart';

abstract final class YildiznameAddressName {
  YildiznameAddressName._();

  static final _word = RegExp(r"^[\p{L}][\p{L}\p{M}'.\-]*$", unicode: true);

  static String? sanitize(String? raw) {
    final words = (raw ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return null;
    if (!_word.hasMatch(words.first)) return null;
    final two = words.length > 1 && _word.hasMatch(words[1])
        ? '${words[0]} ${words[1]}'
        : words.first;
    if (two.length <= kYildiznameMaxAddressNameChars) return two;
    final first = words.first;
    return first.length <= kYildiznameMaxAddressNameChars ? first : null;
  }
}
