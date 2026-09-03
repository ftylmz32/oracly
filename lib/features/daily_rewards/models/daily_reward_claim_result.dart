/// Daily claim outcome — success and failure stay distinguishable.
library;

import 'daily_reward_state.dart';

sealed class DailyRewardClaimResult {
  const DailyRewardClaimResult();

  DailyRewardState get state;
  bool get claimedToday => state.claimedToday;
  int get streak => state.streak;
  bool get isSuccess => this is DailyRewardClaimSuccess;
}

final class DailyRewardClaimSuccess extends DailyRewardClaimResult {
  const DailyRewardClaimSuccess(this.state);
  @override
  final DailyRewardState state;
}

final class DailyRewardClaimFailure extends DailyRewardClaimResult {
  const DailyRewardClaimFailure({required this.message, required this.state});

  final String message;
  @override
  final DailyRewardState state;
}
