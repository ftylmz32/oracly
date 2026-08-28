/// Filter chip labels — only shown when data supports them.
library;

import '../../../core/l10n/l10n.dart';
import '../models/discovery_journal_kind.dart';
import '../models/discovery_journal_range.dart';
import 'discovery_journal_copy.dart';

abstract final class DiscoveryJournalFilterCopy {
  DiscoveryJournalFilterCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get saved => _t('journal.filter_saved');
  static String get featureAll => _t('journal.filter_feature_all');
  static String get themeAll => _t('journal.filter_theme_all');

  static String range(DiscoveryJournalRange value) => switch (value) {
        DiscoveryJournalRange.last7 => _t('journal.filter_7'),
        DiscoveryJournalRange.last30 => _t('journal.filter_30'),
        DiscoveryJournalRange.last90 => _t('journal.filter_90'),
        DiscoveryJournalRange.all => _t('journal.filter_all'),
      };

  static String kind(DiscoveryJournalKind value) =>
      DiscoveryJournalCopy.badge(value);

  static String theme(String raw) => DiscoveryJournalCopy.heroTheme(raw);
}
