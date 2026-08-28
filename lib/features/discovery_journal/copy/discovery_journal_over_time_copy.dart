/// Zaman içinde — observational theme shift copy only.
library;

import '../../../core/l10n/l10n.dart';
import '../../personal_discovery/models/discovery_theme.dart';
import '../../personal_discovery/models/theme_over_time_comparison.dart';
import '../../personal_discovery/models/theme_over_time_period.dart';
import 'discovery_journal_copy.dart';

abstract final class DiscoveryJournalOverTimeCopy {
  DiscoveryJournalOverTimeCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get title => _t('journal.over_time_title');
  static String get earlierLabel => _t('journal.over_time_earlier');
  static String get recentLabel => _t('journal.over_time_recent');

  static String periodLabel(ThemeOverTimePeriod period) => switch (period) {
        ThemeOverTimePeriod.days7 => _t('journal.over_time_7'),
        ThemeOverTimePeriod.days30 => _t('journal.over_time_30'),
        ThemeOverTimePeriod.days90 => _t('journal.over_time_90'),
      };

  static String narrative(ThemeOverTimeComparison comparison) {
    final earlier = DiscoveryJournalCopy.heroTheme(comparison.earlier.theme);
    final recent = DiscoveryJournalCopy.heroTheme(comparison.recent.theme);
    if (!comparison.themesDiffer) {
      return _t('journal.over_time_stable').replaceAll('{theme}', earlier);
    }
    final key = switch (comparison.period) {
      ThemeOverTimePeriod.days7 => 'journal.over_time_shift_7',
      ThemeOverTimePeriod.days30 => 'journal.over_time_shift_30',
      ThemeOverTimePeriod.days90 => 'journal.over_time_shift_90',
    };
    return _t(key)
        .replaceAll('{earlier}', earlier)
        .replaceAll('{recent}', recent);
  }

  static String themeLabel(String raw) {
    return DiscoveryTheme.resolve(raw)?.localized ??
        DiscoveryJournalCopy.heroTheme(raw);
  }
}
