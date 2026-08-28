/// Turns structured [PersonalInsight] into observational copy.
library;

import '../../../core/l10n/l10n.dart';
import '../models/personal_insight.dart';
import 'personal_theme_copy.dart';

abstract final class PersonalInsightPresenter {
  PersonalInsightPresenter._();

  static String _t(String key) => OraclyL10n.t(key);

  static String line(PersonalInsight? insight) {
    if (insight == null) return PersonalThemeCopy.accumulating;
    return _t('theme.copy.line')
        .replaceAll('{theme}', insight.theme)
        .replaceAll('{n}', '${insight.sourceCount}')
        .replaceAll('{why}', insight.explanation);
  }

  static String dailySuffix(PersonalInsight? insight, DateTime day) {
    if (insight == null) return '';
    return ' ${PersonalThemeCopy.todayReflection([insight.theme], day)}';
  }

  static String divert(PersonalInsight current, String previousTheme) {
    return _t('theme.copy.divert')
        .replaceAll('{previous}', previousTheme)
        .replaceAll('{theme}', current.theme);
  }
}
