/// Personal matter lines from real themes. Never invented natal sky.
library;

import '../../../core/l10n/l10n.dart';
import '../../personal_discovery/models/discovery_theme.dart';

abstract final class AstrologyThemeMatter {
  AstrologyThemeMatter._();

  static String of(String life, int seed) {
    final text = life.trim();
    if (text.isEmpty) return '';
    final family = _family(DiscoveryTheme.resolve(text));
    if (family == null) return text;
    return OraclyL10n.t('sky.matter.$family.${seed.abs() % 3}');
  }

  static String? _family(DiscoveryTheme? theme) {
    if (theme == null) return null;
    if (_bind.contains(theme)) return 'bind';
    if (_work.contains(theme)) return 'work';
    if (_inner.contains(theme)) return 'inner';
    if (_spark.contains(theme)) return 'spark';
    return 'inner';
  }

  static const _bind = {
    DiscoveryTheme.love,
    DiscoveryTheme.relationship,
    DiscoveryTheme.communication,
    DiscoveryTheme.family,
    DiscoveryTheme.boundaries,
  };

  static const _work = {
    DiscoveryTheme.career,
    DiscoveryTheme.money,
    DiscoveryTheme.decision,
    DiscoveryTheme.change,
    DiscoveryTheme.redirection,
    DiscoveryTheme.indecision,
  };

  static const _inner = {
    DiscoveryTheme.inward,
    DiscoveryTheme.rest,
    DiscoveryTheme.uncertainty,
    DiscoveryTheme.confidence,
  };

  static const _spark = {
    DiscoveryTheme.creativity,
    DiscoveryTheme.courage,
    DiscoveryTheme.newBeginning,
  };
}
