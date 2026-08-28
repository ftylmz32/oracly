/// Honest copy for the daily discovery suggestion.
library;

import '../../../core/l10n/l10n.dart';
import '../models/discovery_recommend_kind.dart';
import '../models/discovery_recommendation.dart';
import '../models/discovery_recommended_feature.dart';
import '../models/discovery_theme.dart';

abstract final class DiscoveryRecommendationCopy {
  DiscoveryRecommendationCopy._();

  static String get title => OraclyL10n.t('reco.title');

  static String cta(DiscoveryRecommendedFeature feature) =>
      OraclyL10n.t('reco.cta.${feature.name}');

  static String? reason(DiscoveryRecommendation item) {
    if (!item.hasEvidence) return null;
    if (item.kind == DiscoveryRecommendKind.theme) {
      final raw = (item.theme ?? '').trim();
      if (raw.isEmpty) return null;
      final label = _title(DiscoveryTheme.resolve(raw)?.localized ?? raw);
      final key =
          item.recurring ? 'reco.reason.theme_repeat' : 'reco.reason.theme';
      return OraclyL10n.t(key).replaceAll('{theme}', label);
    }
    final source = item.source;
    if (source == null || source.isEmpty) return null;
    if (item.evidenceCount >= 2 && (source == 'dream' || source == 'tarot')) {
      return OraclyL10n.t('reco.reason.source.$source.rise');
    }
    return OraclyL10n.t('reco.reason.source.$source');
  }

  static String _title(String raw) {
    final label = raw.trim();
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
