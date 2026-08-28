/// Local explainable copy for Oracle Core NextAction.
library;

import '../../../core/l10n/l10n.dart';
import '../../personal_discovery/models/discovery_recommended_feature.dart';
import '../../personal_discovery/models/discovery_theme.dart';
import '../models/oracle_next_action.dart';

abstract final class OracleNextActionCopy {
  OracleNextActionCopy._();

  static String line(OracleNextAction action) {
    return OraclyL10n.t('oracle.next.line').replaceAll('{theme}', themeLabel(action));
  }

  static String homeTitle(OracleNextAction action) =>
      OraclyL10n.t('oracle.home.title');

  static String homeBody(OracleNextAction action) {
    return OraclyL10n.t('oracle.home.body').replaceAll(
      '{theme}',
      themeLabel(action),
    );
  }

  static String homeCta(OracleNextAction action) {
    return switch (action.recommendedFeature) {
      DiscoveryRecommendedFeature.companion =>
        OraclyL10n.t('oracle.home.cta.or'),
      _ => OraclyL10n.t('oracle.home.cta.or'),
    };
  }

  static String homeDismiss() => OraclyL10n.t('oracle.home.dismiss');

  static String themeLabel(OracleNextAction action) {
    final raw =
        DiscoveryTheme.resolve(action.theme)?.localized ?? action.theme;
    return _title(raw);
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
