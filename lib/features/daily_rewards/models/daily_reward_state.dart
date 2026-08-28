/// Snapshot of the once-per-day gem claim + existing streak.
library;

import '../../gems/economy/gem_economy.dart';

class DailyRewardState {
  const DailyRewardState({
    required this.streak,
    required this.claimedToday,
    this.rewardAmount = GemEconomy.dailyReward,
  });

  final int streak;
  final bool claimedToday;
  final int rewardAmount;
}
