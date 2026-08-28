/// Localization — one table per key, never a mixed-language fallback.
library;

export 'app_locale.dart';
export 'app_strings_en.dart';
export 'app_strings_ru.dart';
export 'app_strings_tr.dart';
export 'l10n_keys.dart';
export 'oracly_format.dart';
export 'oracly_locale_scope.dart';

import 'package:flutter/widgets.dart';

import 'app_locale.dart';
import 'app_string_tables.dart';
import 'oracly_locale_scope.dart';

abstract final class OraclyL10n {
  OraclyL10n._();

  static String _bound = AppLocale.tr;

  static String get code => _bound;

  static void bind(String? languageCode) {
    _bound = AppLocale.normalize(languageCode);
  }

  /// Subscribe the current build to locale so getters refresh on change.
  static String depend(BuildContext context) {
    final code = OraclyLocaleScope.of(context);
    bind(code);
    return code;
  }

  static String t(String key, {String? languageCode}) {
    final code = AppLocale.normalize(languageCode ?? _bound);
    return AppStringTables.lookup(code, key) ?? key;
  }
}
