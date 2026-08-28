/// Daily personal observation — observational only, never identity claims.
library;

import '../../../core/l10n/l10n.dart';
import '../models/cross_discovery_insight.dart';
import '../models/discovery_theme.dart';

abstract final class DailyObservationCopy {
  DailyObservationCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static const _variants = [
    'observation.daily_a',
    'observation.daily_b',
    'observation.daily_c',
  ];

  static String line(
    CrossDiscoveryInsight insight, {
    DateTime? now,
    int variant = 0,
  }) {
    final n = insight.discoveryCount < 2 ? insight.sourceCount : insight.discoveryCount;
    if (n < 2) return '';
    final theme = _theme(insight.theme);
    if (theme.isEmpty) return '';
    final key = _variants[variant.abs() % _variants.length];
    return _t(key).replaceAll('{theme}', theme);
  }

  static String _theme(String raw) {
    final label = DiscoveryTheme.resolve(raw)?.localized ?? raw.trim();
    if (label.isEmpty) return label;
    final first = label.substring(0, 1);
    final upper = switch (first) {
      'i' => 'İ',
      'ı' => 'I',
      _ => first.toUpperCase(),
    };
    return '$upper${label.substring(1)}';
  }
}
