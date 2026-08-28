/// Tasteful share copy — brand + a short theme, never a private dump.
library;

import '../../../core/l10n/l10n.dart';

abstract final class DiscoveryShareCopy {
  DiscoveryShareCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get share => _t('share.action');
  static String get themeLabel => _t('share.theme');
  static const brand = 'ORACLY';
  static String get unavailable => _t('share.unavailable');
  static String get fallbackHighlight => _t('share.highlight');
  static String get soulMateHighlight => _t('share.soulmate');
  static String get coffeeType => _t(L10nKeys.coffee);
  static String get palmType => _t('profile.palm_title');
  static String get tarotType => _t(L10nKeys.tarot);
  static String get astrologyType => _t(L10nKeys.astrology);
  static String get starMapType => _t(L10nKeys.starMap);
  static String get soulMateType => _t('share.soulmate_type');
  static String get dailyType => _t('share.daily');
}
