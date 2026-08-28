/// Günün Mesajı — reflective daily note. Never a prediction.
library;

import '../../../core/l10n/l10n.dart';
import '../models/daily_return_action.dart';

abstract final class DailyMessageCopy {
  DailyMessageCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get screenTitle => _t('daily_msg.screen');
  static String get listTitle => _t('daily_msg.list_title');
  static String get listSubtitle => _t('daily_msg.list_sub');
  static String get prompt => _t('daily_msg.prompt');
  static String get themeCaption => _t('daily_msg.theme');
  static String get honesty => _t('daily_msg.honesty');
  static String get copyCta => _t('insight.copy');
  static String get copied => _t('insight.copied');
  static String get discoveryTitle => _t('daily_msg.discovery_title');
  static String get exploreTheme => _t('daily_msg.explore');
  static String get drawCard => _t('daily_msg.draw');
  static String get tellDream => _t('daily_msg.dream');
  static String get talkToOr => _t('daily_msg.talk');
  static String get readPalm => _t('daily_msg.palm');
  static String get readCoffee => _t('daily_msg.coffee');
  static String get askTarot => _t('daily_msg.tarot');
  static String get readAstrology => _t('daily_msg.astrology');
  static String get exploreStarMap => _t('daily_msg.starMap');

  static String action(DailyReturnAction value) => switch (value) {
        DailyReturnAction.exploreTheme => exploreTheme,
        DailyReturnAction.drawCard => askTarot,
        DailyReturnAction.tellDream => tellDream,
        DailyReturnAction.talkToOr => talkToOr,
        DailyReturnAction.readPalm => readPalm,
        DailyReturnAction.readCoffee => readCoffee,
        DailyReturnAction.askTarot => askTarot,
        DailyReturnAction.readAstrology => readAstrology,
        DailyReturnAction.exploreStarMap => exploreStarMap,
      };
}
