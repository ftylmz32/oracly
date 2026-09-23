/// Phase 5C — focused certainty-language scan for launch product copy.
library;

import '../../../core/l10n/app_string_tables.dart';
import 'signature_spread_definition.dart';

abstract final class SignatureSpreadCopySafety {
  SignatureSpreadCopySafety._();

  static const trForbidden = <String>[
    'kesinlikle',
    'kesin olacak',
    'kaderinde',
    'kaçınılmaz',
    'garanti',
  ];

  static const enForbidden = <String>[
    'definitely',
    'will happen',
    'guaranteed',
    'destined',
    'inevitable',
  ];

  static const ruForbidden = <String>[
    'обязательно произойд',
    'гарантирован',
    'предначертан',
    'неизбежно',
  ];

  /// Returns keys whose purpose/blurb/guide text contains forbidden certainty.
  static List<String> scanCatalog(List<SignatureSpreadDefinition> catalog) {
    final keys = <String>{};
    for (final d in catalog) {
      keys.add(d.purposeKey);
      keys.add(d.displayBlurbKey);
      for (final p in d.positions) {
        keys.add(p.guidingQuestionKey);
      }
    }
    final hits = <String>[];
    for (final key in keys) {
      if (_hits(key, 'tr', trForbidden) ||
          _hits(key, 'en', enForbidden) ||
          _hits(key, 'ru', ruForbidden)) {
        hits.add(key);
      }
    }
    return List<String>.unmodifiable(hits);
  }

  static bool _hits(String key, String lang, List<String> needles) {
    final value = AppStringTables.lookup(lang, key);
    if (value == null) return false;
    final lower = value.toLowerCase();
    for (final n in needles) {
      if (lower.contains(n.toLowerCase())) return true;
    }
    return false;
  }
}
