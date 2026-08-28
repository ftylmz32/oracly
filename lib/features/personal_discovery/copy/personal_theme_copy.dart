/// Observational theme copy — never "you are X" or fate claims.
library;

import '../../../core/l10n/l10n.dart';
import '../../premium/models/personalization_models.dart';
import '../models/discovery_theme.dart';

abstract final class PersonalThemeCopy {
  PersonalThemeCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get insufficient => _t('theme.copy.insufficient');
  static String get accumulating => _t('theme.copy.accumulating');

  static String recurring(List<String> themes) {
    final clean = _shown(themes);
    if (clean.isEmpty) return insufficient;
    if (clean.length == 1) {
      return _t('theme.copy.recurring1').replaceAll('{a}', clean.first);
    }
    if (clean.length == 2) {
      return _t('theme.copy.recurring2')
          .replaceAll('{a}', clean[0])
          .replaceAll('{b}', clean[1]);
    }
    return _t('theme.copy.recurring3')
        .replaceAll('{a}', clean[0])
        .replaceAll('{b}', clean[1])
        .replaceAll('{c}', clean[2]);
  }

  static String crossModal(List<String> themes) {
    final ids = _ids(themes);
    final clean = _shown(themes);
    if (clean.isEmpty) return insufficient;
    if (clean.length == 1 && ids.first == DiscoveryTheme.change) {
      return _t('theme.copy.cross_change');
    }
    if (clean.length == 1) {
      return _t('theme.copy.cross1').replaceAll('{a}', clean.first);
    }
    if (clean.length == 2) {
      return _t('theme.copy.cross2')
          .replaceAll('{a}', clean[0])
          .replaceAll('{b}', clean[1]);
    }
    return _t('theme.copy.cross3')
        .replaceAll('{a}', clean[0])
        .replaceAll('{b}', clean[1])
        .replaceAll('{c}', clean[2]);
  }

  static String todayReflection(List<String> themes, DateTime day) {
    final clean = _shown(themes);
    if (clean.isEmpty) return insufficient;
    final pool = [
      crossModal(themes),
      recurring(themes),
      _t('theme.copy.today').replaceAll('{focus}', _focus(clean, day)),
    ];
    return pool[day.day.abs() % pool.length];
  }

  static String personalInsight(
    List<String> themes,
    DateTime day, {
    AiPersonality? style,
  }) {
    final clean = _shown(themes);
    if (clean.isEmpty) return insufficient;
    if (clean.length == 1) {
      return _t('theme.copy.insight1').replaceAll('{a}', clean.first);
    }
    final body = _t('theme.copy.insight2')
        .replaceAll('{focus}', _focus(clean, day));
    if (style == AiPersonality.direct) {
      final dot = body.lastIndexOf('. ');
      if (dot < 0) return body;
      return '${body.substring(0, dot + 2)}${_t('theme.copy.insight_direct')}';
    }
    return body;
  }

  static List<DiscoveryTheme?> _ids(List<String> themes) =>
      themes.map(DiscoveryTheme.resolve).toList();

  static List<String> _shown(List<String> themes) => [
        for (final raw in themes)
          if (raw.trim().isNotEmpty)
            DiscoveryTheme.resolve(raw)?.localized ?? raw.trim(),
      ];

  static String _focus(List<String> clean, DateTime day) {
    if (clean.length == 1) return clean.first;
    final a = clean[day.day % clean.length];
    final b = clean[(day.day + 1) % clean.length];
    if (a == b) return a;
    return _t('theme.copy.and').replaceAll('{a}', a).replaceAll('{b}', b);
  }
}
