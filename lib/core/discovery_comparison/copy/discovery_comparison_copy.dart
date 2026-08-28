/// Discovery comparison copy — observational, never progress claims.
library;

import '../../../core/l10n/l10n.dart';
import '../../../features/discovery_journal/copy/discovery_journal_copy.dart';
import '../../../features/personal_discovery/models/discovery_theme.dart';
import '../models/discovery_comparison_kind.dart';

abstract final class DiscoveryComparisonCopy {
  DiscoveryComparisonCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get title => _t('compare.title');
  static String get before => _t('compare.before');
  static String get now => _t('compare.now');
  static String get action => _t('compare.action');
  static String get unavailable => _t('compare.unavailable');
  static String get obstacleToDirectionTarot =>
      _t('compare.obstacle_direction.tarot');

  static String stableTheme(String theme) =>
      _t('compare.stable').replaceAll('{theme}', theme);

  static String themeLabel(DiscoveryTheme theme) =>
      DiscoveryTheme.resolve(theme.label)?.localized ??
      DiscoveryJournalCopy.heroTheme(theme.label);

  static String shift(
    DiscoveryComparisonKind kind,
    String earlier,
    String later,
  ) {
    final key = switch (kind) {
      DiscoveryComparisonKind.tarot => 'compare.shift.tarot',
      DiscoveryComparisonKind.dailyMessage => 'compare.shift.daily',
      DiscoveryComparisonKind.astrology => 'compare.shift.astrology',
      DiscoveryComparisonKind.starMap => 'compare.shift.star',
      DiscoveryComparisonKind.companion => 'compare.shift.or',
    };
    return _t(key)
        .replaceAll('{earlier}', earlier)
        .replaceAll('{later}', later);
  }
}
