/// Date-gated daily gem claim + existing streak increment.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/domain/repositories/user_repository.dart';
import '../../gems/copy/gems_copy.dart';
import '../../gems/economy/gem_economy.dart';
import '../../gems/services/gem_wallet_service.dart';
import '../models/daily_reward_state.dart';

class DailyRewardsService {
  DailyRewardsService(this._user, this._storage, this._wallet);

  final UserRepository _user;
  final LocalStorage _storage;
  final GemWalletService _wallet;

  static const claimedKey = 'daily_reward_claimed_on';

  bool _claiming = false;

  Future<DailyRewardState> load({DateTime? asOf}) async {
    final moment = asOf ?? DateTime.now();
    final profile = await _user.getProfile();
    final claimed = _storage.getString(claimedKey) == _dayKey(moment);
    return DailyRewardState(
      streak: profile.currentStreak,
      claimedToday: claimed,
      rewardAmount: GemEconomy.dailyReward,
    );
  }

  /// Earn first, then mark the day. Never lock the day without gems.
  Future<DailyRewardState> claim({DateTime? asOf}) async {
    final moment = asOf ?? DateTime.now();
    final current = await load(asOf: moment);
    if (current.claimedToday || _claiming) return current;
    _claiming = true;
    try {
      if (_storage.getString(claimedKey) == _dayKey(moment)) {
        return load(asOf: moment);
      }
      final dayKey = _dayKey(moment);
      await _wallet.earn(
        amount: GemEconomy.dailyReward,
        reason: GemsCopy.reasonDailyReward,
        operationId: 'daily_reward_$dayKey',
      );
      await _storage.setString(claimedKey, dayKey);
      await _user.incrementStreak();
      return load(asOf: moment);
    } on GemSpendException {
      return load(asOf: moment);
    } finally {
      _claiming = false;
    }
  }

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
