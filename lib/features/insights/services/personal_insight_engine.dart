/// OR-439 — Local personal insight engine — patterns, not predictions.
library;

import '../../../core/domain/models/personal_insight_report.dart';
import '../../../core/domain/models/personal_insight_theme.dart';
import '../../../core/domain/models/reading.dart';
import '../../../core/l10n/oracly_format.dart';

/// Derives thematic tags and monthly reflections from completed readings.
abstract final class PersonalInsightEngine {
  PersonalInsightEngine._();

  static const minReadingsForThemes = 3;
  static const minReadingsForMonthly = 4;
  static const minThemeOccurrences = 2;

  static const _lexicon = <PersonalInsightTheme, List<String>>{
    PersonalInsightTheme.love: [
      'aşk',
      'ask',
      'sevgi',
      'ilişki',
      'iliski',
      'bağ',
      'bag',
      'lover',
      'lovers',
      'cups',
      'kalp',
      'partner',
    ],
    PersonalInsightTheme.career: [
      'kariyer',
      'iş',
      'is ',
      'meslek',
      'career',
      'work',
      'emperor',
      'pentacles',
      'başarı',
      'basari',
      'profesyon',
    ],
    PersonalInsightTheme.personalGrowth: [
      'gelişim',
      'gelisim',
      'büyüme',
      'buyume',
      'ruhsal',
      'bilgelik',
      'hermit',
      'star',
      'öğren',
      'ogren',
      'growth',
      'spiritual',
    ],
    PersonalInsightTheme.change: [
      'dönüşüm',
      'donusum',
      'değişim',
      'degisim',
      'death',
      'tower',
      'wheel',
      'kapan',
      'yeniden',
      'change',
      'transform',
    ],
    PersonalInsightTheme.courage: [
      'cesaret',
      'güç',
      'guc',
      'strength',
      'chariot',
      'fool',
      'brave',
      'courage',
      'atıl',
      'atil',
    ],
    PersonalInsightTheme.patience: [
      'sabır',
      'sabir',
      'bekle',
      'temperance',
      'hanged',
      'acele etme',
      'patience',
      'sakin',
      'dinlen',
    ],
    PersonalInsightTheme.newBeginnings: [
      'başlangıç',
      'baslangic',
      'yeni',
      'fool',
      ' ace',
      'beginning',
      'start',
      'yenilen',
      'tohum',
    ],
    PersonalInsightTheme.reflection: [
      'yansıma',
      'yansima',
      'iç ses',
      'ic ses',
      'sezgi',
      'moon',
      'düşün',
      'dusun',
      'reflect',
      'medit',
      'sessiz',
    ],
  };

  /// Tag a single reading for journal storage.
  static List<String> tagsForReading({
    required String aiSummary,
    required String cardName,
    String? intention,
  }) {
    final themes = _detectThemes(
      '${aiSummary.toLowerCase()} ${cardName.toLowerCase()} ${intention?.toLowerCase() ?? ''}',
    );
    if (themes.isEmpty) {
      return [PersonalInsightTheme.reflection.storageTag];
    }
    return themes.take(3).map((t) => t.storageTag).toList();
  }

  /// Build insight report from saved history — purely local computation.
  ///
  /// [totalReadings] may exceed [readings] when callers pass a theme window.
  /// [asOf] pins the calendar month window (defaults to wall clock).
  static PersonalInsightReport analyze(
    List<ReadingModel> readings, {
    int? totalReadings,
    DateTime? asOf,
  }) {
    final total = totalReadings ?? readings.length;
    if (readings.length < minReadingsForThemes) {
      return PersonalInsightReport(
        recurringThemes: const [],
        totalReadings: total,
      );
    }

    final counts = <PersonalInsightTheme, int>{};
    for (final reading in readings) {
      final themes = _themesFromReading(reading);
      for (final theme in themes) {
        counts[theme] = (counts[theme] ?? 0) + 1;
      }
    }

    final echoes =
        counts.entries
            .where((e) => e.value >= minThemeOccurrences)
            .map((e) => PersonalThemeEcho(theme: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    final monthly = _monthlyReflection(readings, counts, asOf: asOf);

    return PersonalInsightReport(
      recurringThemes: echoes.take(4).toList(),
      monthlyReflection: monthly,
      totalReadings: total,
    );
  }

  static List<PersonalInsightTheme> _themesFromReading(ReadingModel reading) {
    final fromTags = reading.journal.tags
        .map((tag) => PersonalInsightEngine.fromStorageTag(tag))
        .whereType<PersonalInsightTheme>()
        .toList();
    if (fromTags.isNotEmpty) return fromTags;

    return _detectThemes(
      '${reading.aiSummary.toLowerCase()} '
      '${reading.cardName.toLowerCase()} '
      '${reading.intention?.toLowerCase() ?? ''}',
    );
  }

  static List<PersonalInsightTheme> _detectThemes(String normalized) {
    final found = <PersonalInsightTheme>[];
    for (final entry in _lexicon.entries) {
      for (final token in entry.value) {
        if (normalized.contains(token)) {
          found.add(entry.key);
          break;
        }
      }
    }
    return found;
  }

  static PersonalMonthlyReflection? _monthlyReflection(
    List<ReadingModel> readings,
    Map<PersonalInsightTheme, int> allTimeCounts, {
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);
    final monthReadings = readings
        .where(
          (r) =>
              !r.createdAt.isBefore(monthStart) &&
              r.createdAt.isBefore(monthEnd),
        )
        .toList();

    if (monthReadings.length < minReadingsForMonthly) return null;

    final monthCounts = <PersonalInsightTheme, int>{};
    for (final reading in monthReadings) {
      for (final theme in _themesFromReading(reading)) {
        monthCounts[theme] = (monthCounts[theme] ?? 0) + 1;
      }
    }

    final top = monthCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (top.isEmpty) return null;

    final leading = top
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .take(3)
        .toList();
    if (leading.isEmpty) {
      leading.add(top.first.key);
    }

    return PersonalMonthlyReflection(
      monthLabel: _monthLabel(now),
      observation: _composeObservation(leading, monthReadings.length),
      recurringThemes: leading,
      readingCount: monthReadings.length,
    );
  }

  static String _composeObservation(
    List<PersonalInsightTheme> themes,
    int count,
  ) {
    if (themes.length == 1) {
      return 'Bu ay açılımların sık sık ${themes.first.label.toLowerCase()} '
          'temasına değindi — kendi yolculuğunda bir desen beliriyor olabilir.';
    }
    if (themes.length == 2) {
      return 'Bu ay okumaların genellikle ${themes[0].label.toLowerCase()} '
          've ${themes[1].label.toLowerCase()} temalarına döndü — '
          'sanki iç sesin bu konularda nazikçe kalıyor olabilir.';
    }
    return 'Bu ay $count açılımda ${themes[0].label.toLowerCase()}, '
        '${themes[1].label.toLowerCase()} ve ${themes[2].label.toLowerCase()} '
        'temaları yankılandı — bir ritim hissediliyor olabilir.';
  }

  static String _monthLabel(DateTime date) => OraclyFormat.monthYear(date);

  static PersonalInsightTheme? fromStorageTag(String tag) {
    if (!tag.startsWith('insight:')) return null;
    return PersonalInsightTheme.fromId(tag.substring(8));
  }
}
