/// Real discovery themes only. Never invent a personal history.
library;

import '../../../core/l10n/l10n.dart';
import '../../personal_discovery/models/discovery_theme.dart';

abstract final class CoffeeFortuneLife {
  CoffeeFortuneLife._();

  static const _path = {'road', 'key'};
  static const _bind = {'heart', 'ring', 'person'};
  static const _news = {'bird', 'letter'};
  static const _hold = {'mountain', 'eye', 'tree'};
  static const _work = {'key', 'road', 'mountain'};

  static String phrase(Set<String> ids, List<String> themes) {
    for (final theme in themes) {
      final resolved = DiscoveryTheme.resolve(theme);
      if (resolved == null || !_fits(resolved, ids)) continue;
      if (resolved == DiscoveryTheme.change) {
        return OraclyL10n.t('fortune.cup.theme.change');
      }
      return OraclyL10n.t('cup.read.you.theme')
          .replaceAll('{life}', resolved.localized);
    }
    return '';
  }

  static bool _fits(DiscoveryTheme theme, Set<String> ids) {
    return switch (theme) {
      DiscoveryTheme.love ||
      DiscoveryTheme.relationship ||
      DiscoveryTheme.family =>
        ids.any(_bind.contains),
      DiscoveryTheme.career || DiscoveryTheme.redirection =>
        ids.any(_work.contains),
      DiscoveryTheme.change ||
      DiscoveryTheme.newBeginning ||
      DiscoveryTheme.decision ||
      DiscoveryTheme.indecision ||
      DiscoveryTheme.uncertainty =>
        ids.any(_path.contains) || ids.contains('mountain'),
      DiscoveryTheme.communication => ids.any(_news.contains),
      DiscoveryTheme.courage ||
      DiscoveryTheme.confidence ||
      DiscoveryTheme.boundaries =>
        ids.contains('key') ||
            ids.contains('mountain') ||
            ids.contains('ring'),
      DiscoveryTheme.inward || DiscoveryTheme.rest => ids.any(_hold.contains),
      DiscoveryTheme.creativity =>
        ids.contains('star') || ids.contains('tree'),
      DiscoveryTheme.money => false,
    };
  }
}
