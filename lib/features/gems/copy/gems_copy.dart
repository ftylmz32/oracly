/// Mücevherler user-facing copy.
library;

import '../../../core/l10n/l10n.dart';

abstract final class GemsCopy {
  GemsCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get screenTitle => _t('gems.screen');
  static String get balanceLabel => _t('gems.balance');
  static String get economyTitle => _t('gems.economy');
  static String get starterChip => _t('gems.starter_chip');
  static String get dailyChip => _t('gems.daily_chip');
  static String get tarotChip => _t('gems.cost_chip');
  static String get tarotLabel => _t('gems.tarot_label');
  static String get dailyValueSuffix => _t('gems.day_suffix');
  static String get dailyRewardHint => _t('gems.daily_hint');
  static String get shopHonesty => _t('gems.shop_honesty');
  static String get gemUnit => _t('gems.unit');
  static String get whatTitle => _t('gems.what_title');
  static String get whatBody => _t('gems.what_body');
  static String get earnTitle => _t('gems.earn_title');
  static String get earnBody => _t('gems.earn_body');
  static String get spendTitle => _t('gems.spend_title');
  static String get spendBody => _t('gems.spend_body');
  static String get historyTitle => _t('gems.history');
  static String get historyEmpty => _t('gems.history_empty');
  static String get dailyRewardLink => _t('gems.daily_link');
  static String get insufficient => _t('gems.insufficient');
  static String get openGemsAction => _t('gems.open');
  static String costLabel(int amount) =>
      _t('gems.cost_n').replaceAll('{n}', '$amount');
  static String get confirmTitle => _t('gems.confirm_title');
  static String confirmBody(int amount) =>
      _t('gems.confirm_body').replaceAll('{cost}', costLabel(amount));
  static String confirmBodyWithBalance({
    required int cost,
    required int balance,
  }) =>
      _t('gems.confirm_body_with_balance')
          .replaceAll('{cost}', costLabel(cost))
          .replaceAll('{balance}', costLabel(balance));
  static String confirmBodyPurpose({
    required int cost,
    required int balance,
    required String reason,
  }) =>
      _t('gems.confirm_body_purpose')
          .replaceAll('{reason}', reason)
          .replaceAll('{cost}', costLabel(cost))
          .replaceAll('{balance}', costLabel(balance));
  static String claimReceived(int amount) => _t('gems.claim_received')
      .replaceAll('{amount}', costLabel(amount));

  /// Keep [insufficient] as-is (tests assert exact string).
  static String insufficientCost(int cost) =>
      _t('gems.insufficient_cost').replaceAll('{cost}', costLabel(cost));
  static String get reasonDailyReward => _t('gems.reason.daily');
  static String get reasonStarter => _t('gems.reason.starter');
  static String get reasonTarot => _t('gems.reason.tarot');
  static String get reasonDream => _t('gems.reason.dream');
  static String get reasonCoffee => _t('gems.reason.coffee');
  static String get reasonPalm => _t('gems.reason.palm');
  static String get reasonSoulMate => _t('gems.reason.soulmate');
  static String get reasonRefund => _t('gems.reason.refund');
  static String get cancel => _t(L10nKeys.cancel);
  static String get busy => _t('gems.busy');
}
