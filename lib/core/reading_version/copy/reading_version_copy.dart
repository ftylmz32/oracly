/// Reading version UI copy.
library;

import '../../l10n/l10n.dart';

abstract final class ReadingVersionCopy {
  ReadingVersionCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get newReading => _t('version.new_reading');
  static String get original => _t('version.original');
  static String get compare => _t('version.compare');
  static String get compareTitle => _t('version.compare.title');
  static String get unchanged => _t('version.unchanged');

  static String revision(int number) =>
      _t('version.revision').replaceAll('{n}', '$number');
}
