/// Date-gated daily gem claim + existing streak increment.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/domain/repositories/user_repository.dart';
import '../../gems/copy/gems_copy.dart';
import '../../gems/economy/gem_economy.dart';
import '../../gems/services/gem_wallet_service.dart';
import '../copy/daily_rewards_copy.dart';
import '../models/daily_reward_claim_result.dart';
import '../models/daily_reward_state.dart';

class DailyRewardsService {
  DailyRewardsService(this._user, this._storage, this._wallet);

  final UserRepository _user;
  final LocalStorage _storage;
  final GemWalletService _wallet;

  static const claimedKey = 'daily_reward_claimed_on';

  bool _claiming = false;
  String? _claimedDayInMemory;

  Future<DailyRewardState> load({DateTime? asOf}) async {
    final moment = asOf ?? DateTime.now();
    final profile = await _user.getProfile();
    final today = _dayKey(moment);
    final claimed =
        _claimedDayInMemory == today || _storage.getString(claimedKey) == today;
    return DailyRewardState(
      streak: profile.currentStreak,
      claimedToday: claimed,
      rewardAmount: GemEconomy.dailyReward,
    );
  }

  /// Server time and the server ledger decide eligibility and amount.
  Future<DailyRewardClaimResult> claim({DateTime? asOf}) async {
    final moment = asOf ?? DateTime.now();
    final current = await load(asOf: moment);
    if (current.claimedToday) {
      return DailyRewardClaimSuccess(current);
    }
    if (_claiming) {
      return DailyRewardClaimFailure(message: GemsCopy.busy, state: current);
    }
    _claiming = true;
    try {
      if (_storage.getString(claimedKey) == _dayKey(moment)) {
        return DailyRewardClaimSuccess(await load(asOf: moment));
      }
      try {
        final result = await _wallet.claimDaily(
          idempotencyKey: 'daily-reward-request-v1',
        );
        if (result == null) {
          return DailyRewardClaimFailure(
            message: DailyRewardsCopy.claimFailed,
            state: current,
          );
        }
        final dayKey = result.serverDay ?? _dayKey(moment);
        // Server claim is authoritative. Reflect it immediately in memory so
        // a local SharedPreferences write failure cannot make a successfully
        // granted reward look unclaimed in this session. Restart recovery is
        // still safe because the server ledger is idempotent.
        _claimedDayInMemory = dayKey;
        await _storage.setString(claimedKey, dayKey);
        if (result.applied && !result.idempotent) {
          await _user.incrementStreak();
        }
      } on GemSpendException catch (e) {
        return DailyRewardClaimFailure(
          message: e.message,
          state: await load(asOf: moment),
        );
      }

      return DailyRewardClaimSuccess(await load(asOf: moment));
    } catch (_) {
      return DailyRewardClaimFailure(
        message: DailyRewardsCopy.claimFailed,
        state: await load(asOf: moment),
      );
    } finally {
      _claiming = false;
    }
  }

  static String _dayKey(DateTime date) {
    final utc = date.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
  }
}
