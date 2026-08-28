/// Date-aware quiet lines — never fortune, never a slogan.
library;

import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';

abstract final class DailyMessageCatalogue {
  DailyMessageCatalogue._();

  static const _emptyKeys = <String>[
    'daily.empty.0',
    'daily.empty.1',
    'daily.empty.2',
    'daily.empty.3',
    'daily.empty.4',
    'daily.empty.5',
    'daily.empty.6',
    'daily.empty.7',
    'daily.empty.8',
    'daily.empty.9',
    'daily.empty.10',
    'daily.empty.11',
    'daily.empty.12',
    'daily.empty.13',
    'daily.empty.14',
    'daily.empty.15',
  ];

  static String weekday(DateTime day, {String? languageCode}) {
    final tag = AppLocale.normalize(languageCode ?? OraclyL10n.code);
    try {
      return DateFormat.EEEE(tag).format(day);
    } catch (_) {
      return OraclyFormat.dayMonth(day, languageCode: tag);
    }
  }

  static String month(DateTime day, {String? languageCode}) {
    final tag = AppLocale.normalize(languageCode ?? OraclyL10n.code);
    try {
      return DateFormat.MMMM(tag).format(day);
    } catch (_) {
      return OraclyL10n.t('tarot.month.l.${day.month}', languageCode: tag);
    }
  }

  /// Empty-history pool — calm, short, never a personal claim.
  static List<String> dateAware(DateTime day, {String? languageCode}) {
    final tag = AppLocale.normalize(languageCode ?? OraclyL10n.code);
    final w = weekday(day, languageCode: tag);
    final m = month(day, languageCode: tag);
    return [
      for (final key in _emptyKeys)
        OraclyL10n.t(key, languageCode: tag)
            .replaceAll('{weekday}', w)
            .replaceAll('{month}', m),
    ];
  }

  static String structureOf(String text) {
    final t = text.trim().toLowerCase();
    if (t.startsWith('son birkaç') || t.startsWith('in recent')) {
      return 'son-birkaç';
    }
    if (t.startsWith('keşiflerinde') || t.startsWith('the trace of')) {
      return 'kesiflerinde';
    }
    if (t.startsWith('geri dönüp') || t.startsWith('looking back')) {
      return 'geri-donup';
    }
    if (t.contains('küçük bir sonraki') || t.contains('a small next step')) {
      return 'next-step';
    }
    if (t.contains('bu yüzden') || t.contains('so with')) {
      return 'direction';
    }
    if (t.contains('için bugün ayrılmış') || t.contains("today's room")) {
      return 'ayrilmis';
    }
    if (t.contains('uydurma bir kehanet') || t.contains('invented prophecy')) {
      return 'ay-acele';
    }
    if (t.contains('kısa bir not') || t.contains('short note')) {
      return 'gun-ritim';
    }
    if (t.startsWith('acele etmeden') || t.startsWith('pausing without')) {
      return 'acele-etmeden';
    }
    if (t.startsWith('küçük bir boşluk') || t.startsWith('leaving a small')) {
      return 'bosluk';
    }
    if (t.startsWith('sadece nefes') || t.startsWith('making room only')) {
      return 'nefes';
    }
    if (t.startsWith('bir düşünceyi') || t.startsWith('naming a thought')) {
      return 'adlandir';
    }
    if (t.startsWith('gürültüyü') || t.startsWith('quieting the')) {
      return 'gurultu';
    }
    if (t.startsWith('kendine') || t.startsWith('giving yourself')) {
      return 'kendine';
    }
    if (t.contains('sessizliğinde') || t.contains('quiet of')) {
      return 'sessizlik';
    }
    if (t.contains('ritminde') || t.contains('rhythm of')) {
      return 'ritim';
    }
    if (t.startsWith('bugün') || t.startsWith('no grand') || t.startsWith('today')) {
      return 'bugun';
    }
    return 'other';
  }
}
