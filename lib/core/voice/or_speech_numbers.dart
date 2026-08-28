/// Speech-only number, date, and abbreviation forms. Visible text is untouched.
library;

import 'package:intl/intl.dart';

import '../l10n/app_locale.dart';
import '../l10n/l10n.dart';

abstract final class OrSpeechNumbers {
  OrSpeechNumbers._();

  static String prepare(String raw, {String? languageCode}) {
    final lang = AppLocale.normalize(languageCode ?? OraclyL10n.code);
    var text = raw;
    if (lang == AppLocale.tr) {
      text = text.replaceAllMapped(
        RegExp(r'(?<!yüzde )%(\d+(?:[.,]\d+)?)'),
        (m) => 'yüzde ${m[1]}',
      );
      text = text.replaceAllMapped(
        RegExp(r'(?<!yüzde )(\d+(?:[.,]\d+)?)\s*%'),
        (m) => 'yüzde ${m[1]}',
      );
      text = text.replaceAll(RegExp(r'\bvs\.\b', caseSensitive: false), 'vesaire');
      text = text.replaceAll(RegExp(r'\bvb\.\b', caseSensitive: false), 've benzeri');
      text = text.replaceAll(RegExp(r'\bö[rR]n\.\b'), 'örneğin');
    }
    text = text.replaceAllMapped(
      RegExp(r'\b(\d{1,2})[./](\d{1,2})[./](\d{4})\b'),
      (m) => _date(m, lang),
    );
    text = text.replaceAllMapped(
      RegExp(r'\b(\d{1,2}):(\d{2})\b'),
      (m) => _clock(m, lang),
    );
    return text;
  }

  static String _date(Match m, String lang) {
    final day = int.tryParse(m[1] ?? '') ?? 0;
    final month = int.tryParse(m[2] ?? '') ?? 0;
    final year = int.tryParse(m[3] ?? '') ?? 0;
    if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1) {
      return m[0] ?? '';
    }
    final date = DateTime(year, month, day);
    return DateFormat.yMMMMd(lang).format(date);
  }

  static String _clock(Match m, String lang) {
    final h = int.tryParse(m[1] ?? '') ?? 0;
    final min = int.tryParse(m[2] ?? '') ?? 0;
    if (h > 23 || min > 59) return m[0] ?? '';
    final date = DateTime(2000, 1, 1, h, min);
    if (lang == AppLocale.en) return DateFormat.jm(lang).format(date);
    if (lang == AppLocale.tr) {
      return 'saat ${DateFormat.Hm(lang).format(date).replaceFirst(':', '.')}';
    }
    return DateFormat.Hm(lang).format(date);
  }
}
