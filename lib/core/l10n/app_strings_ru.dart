/// Russian strings — flattened from the shared triple table.
library;

import 'app_locale.dart';
import 'app_string_tables.dart';

abstract final class AppStringsRu {
  AppStringsRu._();

  static String? lookup(String key) =>
      AppStringTables.lookup(AppLocale.ru, key);
}
