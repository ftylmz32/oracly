/// Locale-aware dates, times, relative days, and integers for TR / EN / RU.
library;

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'l10n.dart';

abstract final class OraclyFormat {
  OraclyFormat._();

  static bool _datesReady = false;
  static Future<void>? _init;

  /// Call once at app start (and in tests) before formatting dates.
  static Future<void> ensureInitialized() {
    return _init ??= () async {
      await Future.wait([
        initializeDateFormatting(AppLocale.tr),
        initializeDateFormatting(AppLocale.en),
        initializeDateFormatting(AppLocale.ru),
      ]);
      _datesReady = true;
    }();
  }

  static String _lang([String? languageCode]) =>
      AppLocale.normalize(languageCode ?? OraclyL10n.code);

  static String _localeTag([String? languageCode]) => _lang(languageCode);

  static String _safeDate(
    DateTime date,
    String Function(String tag) format, {
    String? languageCode,
  }) {
    final tag = _localeTag(languageCode);
    if (_datesReady) return format(tag);
    // Sync fallback before init — localized month tables, never TR-only hardcode.
    final month = OraclyL10n.t('tarot.month.l.${date.month}', languageCode: tag);
    return switch (tag) {
      AppLocale.en => '$month ${date.day}, ${date.year}',
      _ => '${date.day} $month ${date.year}',
    };
  }

  /// Full calendar date — natural for each language.
  static String date(DateTime date, {String? languageCode}) {
    return _safeDate(
      date,
      (tag) => DateFormat.yMMMMd(tag).format(date),
      languageCode: languageCode,
    );
  }

  /// Day + month, no year — journal tiles.
  static String dayMonth(DateTime date, {String? languageCode}) {
    final tag = _localeTag(languageCode);
    if (_datesReady) return DateFormat.MMMMd(tag).format(date);
    final month = OraclyL10n.t('tarot.month.l.${date.month}', languageCode: tag);
    return switch (tag) {
      AppLocale.en => '$month ${date.day}',
      _ => '${date.day} $month',
    };
  }

  /// Compact day + short month + year — history rows.
  static String dateCompact(DateTime date, {String? languageCode}) {
    final tag = _localeTag(languageCode);
    if (_datesReady) return DateFormat.yMMMd(tag).format(date);
    final month = OraclyL10n.t('tarot.month.s.${date.month}', languageCode: tag);
    return switch (tag) {
      AppLocale.en => '$month ${date.day}, ${date.year}',
      _ => '${date.day} $month ${date.year}',
    };
  }

  /// Month + year — journey begin labels.
  static String monthYear(DateTime date, {String? languageCode}) {
    final tag = _localeTag(languageCode);
    if (_datesReady) return DateFormat.yMMMM(tag).format(date);
    final month = OraclyL10n.t('tarot.month.l.${date.month}', languageCode: tag);
    return '$month ${date.year}';
  }

  /// Clock time — 24h for TR/RU, 12h for EN.
  ///
  /// Deferred startup awaits [ensureInitialized] AFTER the first frame
  /// (see main.dart), so a screen can render before ICU locale data is
  /// ready. Fall back to a manual, still locale-correct format instead of
  /// throwing a LocaleDataException — matches [_safeDate]'s pattern.
  static String time(DateTime date, {String? languageCode}) {
    final tag = _localeTag(languageCode);
    if (!_datesReady) return _safeTime(date, tag);
    if (tag == AppLocale.en) return DateFormat.jm(tag).format(date);
    return DateFormat.Hm(tag).format(date);
  }

  static String _safeTime(DateTime date, String tag) {
    if (tag == AppLocale.en) {
      final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final suffix = date.hour < 12 ? 'AM' : 'PM';
      return '$hour12:$minute $suffix';
    }
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Numeric calendar form for forms / stamps (locale separators).
  static String dateNumeric(DateTime date, {String? languageCode}) {
    return _safeDate(
      date,
      (tag) => DateFormat.yMd(tag).format(date),
      languageCode: languageCode,
    );
  }

  /// Today / yesterday / compact date.
  static String relativeDay(
    DateTime date, {
    DateTime? now,
    String? languageCode,
  }) {
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);
    final day = DateTime(date.year, date.month, date.day);
    final lang = _lang(languageCode);
    if (day == today) return OraclyL10n.t('format.today', languageCode: lang);
    if (day == today.subtract(const Duration(days: 1))) {
      return OraclyL10n.t('format.yesterday', languageCode: lang);
    }
    return dateCompact(date, languageCode: lang);
  }

  /// Relative day with clock — e.g. dream history rows.
  static String relativeDayTime(
    DateTime date, {
    DateTime? now,
    String? languageCode,
  }) {
    final lang = _lang(languageCode);
    final day = relativeDay(date, now: now, languageCode: lang);
    return OraclyL10n.t('format.day_time', languageCode: lang)
        .replaceAll('{day}', day)
        .replaceAll('{time}', time(date, languageCode: lang));
  }

  /// Grouped integers — gems, counts (TR `.` · EN `,` · RU thin space).
  static String integer(int value, {String? languageCode}) {
    final tag = _localeTag(languageCode);
    return NumberFormat.decimalPattern(tag).format(value);
  }

  /// Small card / arcana index — no grouping.
  static String cardNumber(int value, {String? languageCode}) {
    final tag = _localeTag(languageCode);
    return NumberFormat('0', tag).format(value);
  }

  /// Character count for text fields — e.g. dream write sheet.
  static String charCount(int value, {String? languageCode}) {
    final lang = _lang(languageCode);
    return OraclyL10n.t('format.char_count', languageCode: lang)
        .replaceAll('{count}', integer(value, languageCode: lang));
  }
}
