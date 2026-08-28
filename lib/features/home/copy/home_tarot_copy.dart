/// Home Tarot tile copy — TR / EN / RU.
library;

import '../../../core/l10n/l10n.dart';

abstract final class HomeTarotCopy {
  HomeTarotCopy._();

  static String get title => OraclyL10n.t('home.tarot.title');
  static String get caption => OraclyL10n.t('home.tarot.caption');
}
