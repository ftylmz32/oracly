/// Daily reward providers — claim + streak, one calendar day.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/providers/backend_providers.dart' as backend;
import '../../gems/providers/gem_providers.dart';
import '../services/daily_rewards_service.dart';

final dailyRewardsServiceProvider = Provider<DailyRewardsService>((ref) {
  final gateway = ref.watch(backend.firebaseAuthGatewayProvider);
  ref.watch(backend.firebaseAuthUserProvider);
  ref.watch(backend.localDataOwnerEpochProvider);
  return DailyRewardsService(
    ref.watch(userRepositoryProvider),
    ref.watch(localStorageProvider),
    ref.watch(gemWalletServiceProvider),
    currentOwnerId: () => gateway?.currentUser?.uid,
  );
});
