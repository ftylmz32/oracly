/// Destem — informational deck browser copy.
library;

import '../../../../core/l10n/l10n.dart';
import '../../deck/oracly_tarot_enums.dart';

abstract final class DestemCopy {
  DestemCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get title => _t('tarot.destem.title');
  static String get link => _t('tarot.destem.link');
  static String get subtitle => _t('tarot.destem.subtitle');
  static String get seen => _t('tarot.destem.seen');
  static String get openHint => _t('tarot.destem.open');

  static String get sectionMajor => _t('tarot.destem.section.major');
  static String get sectionWands => _t('tarot.destem.section.wands');
  static String get sectionCups => _t('tarot.destem.section.cups');
  static String get sectionSwords => _t('tarot.destem.section.swords');
  static String get sectionPentacles => _t('tarot.destem.section.pentacles');

  static String suitSection(OraclyTarotSuit suit) => switch (suit) {
        OraclyTarotSuit.wands => sectionWands,
        OraclyTarotSuit.cups => sectionCups,
        OraclyTarotSuit.swords => sectionSwords,
        OraclyTarotSuit.pentacles => sectionPentacles,
        OraclyTarotSuit.none => sectionMajor,
      };
}
