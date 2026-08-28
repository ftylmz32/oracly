/// Daily reward providers — claim + streak, one calendar day.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../gems/providers/gem_providers.dart';
import '../services/daily_rewards_service.dart';

final dailyRewardsServiceProvider = Provider<DailyRewardsService>((ref) {
  return DailyRewardsService(
    ref.watch(userRepositoryProvider),
    ref.watch(localStorageProvider),
    ref.watch(gemWalletServiceProvider),
  );
});
