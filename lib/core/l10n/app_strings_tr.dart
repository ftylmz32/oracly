/// Turkish strings — flattened from the shared triple table.
library;

import 'app_locale.dart';
import 'app_string_tables.dart';

abstract final class AppStringsTr {
  AppStringsTr._();

  static String resolve(String key, {String? fallback}) =>
      AppStringTables.lookup(AppLocale.tr, key) ?? fallback ?? key;
}
