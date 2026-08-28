/// Günlük Ödüller user-facing copy.
library;

import '../../../core/l10n/l10n.dart';
import '../../gems/economy/gem_economy.dart';
import '../../gems/data/gem_display.dart';

abstract final class DailyRewardsCopy {
  DailyRewardsCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get screenTitle => _t('rewards.screen');
  static String get subtitle => _t('rewards.subtitle');
  static String get giftTitle => _t('rewards.gift');
  static String get gemUnit => _t('rewards.unit');
  static String get todayLabel => _t('rewards.today');
  static String get claimLabel => _t('rewards.claim');
  static String get claimShort => _t('rewards.claim_short');
  static String get claimedLabel => _t('rewards.claimed');
  static String get streakLabel => _t('rewards.streak');
  static String get streakHint => _t('rewards.streak_hint');

  static String rewardAmountLabel([int amount = GemEconomy.dailyReward]) =>
      _t('rewards.amount').replaceAll('{n}', GemDisplay.format(amount));
}
