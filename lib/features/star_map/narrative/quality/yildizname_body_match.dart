/// Whole-word-ish body presence helper (avoids `ay` matching inside a
/// longer, unrelated word — see [YildiznameLexicalToken.body]).
library;

import 'yildizname_lexical_token.dart';

abstract final class YildiznameBodyMatch {
  YildiznameBodyMatch._();

  /// One compiled, cached pattern per body — reused across every house/aspect
  /// grounding check (never recompiled per call; see Phase 8C.2b).
  static final _cache = <String, RegExp>{};

  static bool has(String prose, String body, List<String> tokens) {
    final re = _cache.putIfAbsent(
      body,
      () => YildiznameLexicalToken.compile(
        YildiznameLexicalToken.anyBody(tokens),
      ),
    );
    return re.hasMatch(YildiznameLexicalToken.normalizeProse(prose));
  }
}
