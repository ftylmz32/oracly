/// Card of the Day — reflective, never predictive.
library;

import '../../../core/l10n/l10n.dart';

abstract final class CardOfTheDayCopy {
  CardOfTheDayCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get title => _t('ritual.card_of_day.title');
  static String get openCta => _t('ritual.card_of_day.open');
  static String get drawCta => _t('ritual.card_of_day.draw');
  static String get orOpen => _t('ritual.card_of_day.or');
  static String get honesty => _t('ritual.card_of_day.honesty');
  static String get guidanceLabel => _t('ritual.card_of_day.guidance');
}
