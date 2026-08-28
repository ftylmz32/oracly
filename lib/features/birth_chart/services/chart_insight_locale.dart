/// Locale helpers for generated birth-chart presentation copy.
library;

import '../../../core/l10n/l10n.dart';
import '../models/zodiac_sign_id.dart';

abstract final class ChartInsightLocale {
  ChartInsightLocale._();

  static String fill(String key, Map<String, String> vars) {
    var out = OraclyL10n.t(key);
    for (final entry in vars.entries) {
      out = out.replaceAll('{${entry.key}}', entry.value);
    }
    return out;
  }

  static String signName(ZodiacSignId sign) =>
      sign.labeled(OraclyL10n.code);

  static String elementName(ChartElement element) =>
      OraclyL10n.t('birth.element.${element.name}');

  static List<String> traits(ZodiacSignId sign) => [
        OraclyL10n.t('birth.trait.${sign.id}.0'),
        OraclyL10n.t('birth.trait.${sign.id}.1'),
      ];

  static String career(ZodiacSignId sign) =>
      OraclyL10n.t('birth.career.${sign.id}');

  static String joinAnd(List<String> parts) {
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    final conj = OraclyL10n.t('birth.conj_and');
    return '${parts.sublist(0, parts.length - 1).join(', ')} $conj ${parts.last}';
  }
}
