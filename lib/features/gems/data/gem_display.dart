/// Formats the authoritative gem balance for chrome.
library;

import '../../../core/l10n/oracly_format.dart';

abstract final class GemDisplay {
  GemDisplay._();

  static String format(int amount, {String? languageCode}) =>
      OraclyFormat.integer(amount, languageCode: languageCode);
}
