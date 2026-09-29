/// Date-gated daily gem claim + existing streak increment.
library;

import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/data/datasources/local_storage.dart';
import '../../../core/domain/repositories/user_repository.dart';
import '../../gems/copy/gems_copy.dart';
import '../../gems/economy/gem_economy.dart';
import '../../gems/services/gem_wallet_service.dart';
import '../copy/daily_rewards_copy.dart';
import '../models/daily_reward_claim_result.dart';
import '../models/daily_reward_state.dart';

class DailyRewardsService {
  DailyRewardsService(
    this._user,
    this._storage,
    this._wallet, {
    String? Function()? currentOwnerId,
    // ignore: prefer_initializing_formals
  }) : _currentOwnerId = currentOwnerId;

  final UserRepository _user;
  final LocalStorage _storage;
  final GemWalletService _wallet;
  final String? Function()? _currentOwnerId;

  static const claimedKey = 'daily_reward_claimed_on';

  bool _claiming = false;
  String? _claimedDayInMemory;
  String? _memoryOwner;

  Future<DailyRewardState> load({DateTime? asOf}) async {
    final moment = asOf ?? DateTime.now();
    final profile = await _user.getProfile();
    final today = _dayKey(moment);
    final remembered = _claimedDayInMemory == today && _memoryStillOwner;
    final claimed = remembered || _storage.getString(claimedKey) == today;
    return DailyRewardState(
      streak: profile.currentStreak,
      claimedToday: claimed,
      rewardAmount: GemEconomy.dailyReward,
    );
  }

  /// Server time and the server ledger decide eligibility and amount.
  /// `daily_reward_claimed_on` is a UX cache. A failed local write does not
  /// turn a successful server grant into a failed claim. Restart recovers
  /// through the idempotent server ledger, which does not increment streak.
  Future<DailyRewardClaimResult> claim({DateTime? asOf}) async {
    final moment = asOf ?? DateTime.now();
    final current = await load(asOf: moment);
    if (current.claimedToday) return DailyRewardClaimSuccess(current);
    if (_claiming) {
      return DailyRewardClaimFailure(message: GemsCopy.busy, state: current);
    }
    _claiming = true;
    final captured = _currentOwnerId?.call()?.trim();
    try {
      if (_storage.getString(claimedKey) == _dayKey(moment)) {
        return DailyRewardClaimSuccess(await load(asOf: moment));
      }
      final result = await _wallet.claimDaily(
        idempotencyKey: 'daily-reward-request-v1',
      );
      if (result == null) {
        return DailyRewardClaimFailure(
          message: DailyRewardsCopy.claimFailed,
          state: current,
        );
      }
      final committed = await _commitClaim(
        captured: captured,
        dayKey: result.serverDay ?? _dayKey(moment),
        incrementStreak: result.applied && !result.idempotent,
      );
      if (!committed) {
        return DailyRewardClaimFailure(
          message: DailyRewardsCopy.claimFailed,
          state: current,
        );
      }
      return DailyRewardClaimSuccess(await load(asOf: moment));
    } on GemSpendException catch (e) {
      return DailyRewardClaimFailure(
        message: e.message,
        state: await load(asOf: moment),
      );
    } catch (_) {
      return DailyRewardClaimFailure(
        message: DailyRewardsCopy.claimFailed,
        state: await load(asOf: moment),
      );
    } finally {
      _claiming = false;
    }
  }

  bool get _memoryStillOwner {
    final read = _currentOwnerId;
    if (read == null) return true;
    final owner = _memoryOwner;
    return owner != null && owner.isNotEmpty && owner == read()?.trim();
  }

  bool _sameOwner(String? captured) {
    final read = _currentOwnerId;
    if (read == null) return true;
    final live = read()?.trim();
    final local = _storage.getString(UserLocalDataIsolation.ownerKey)?.trim();
    return captured != null &&
        captured.isNotEmpty &&
        captured == live &&
        captured == local;
  }

  Future<bool> _commitClaim({
    required String? captured,
    required String dayKey,
    required bool incrementStreak,
  }) {
    return UserLocalDataIsolation.runOwnerScopedMutation(() async {
      if (!_sameOwner(captured)) return false;
      _claimedDayInMemory = dayKey;
      _memoryOwner = captured;
      try {
        await _storage.setString(claimedKey, dayKey);
      } catch (_) {}
      if (!incrementStreak || !_sameOwner(captured)) return true;
      try {
        await _user.incrementStreak();
      } catch (_) {}
      return true;
    });
  }

  static String _dayKey(DateTime date) {
    final utc = date.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
  }
}
