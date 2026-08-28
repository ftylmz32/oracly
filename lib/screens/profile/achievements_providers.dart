/// Achievements list provider — shared by AchievementsScreen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/domain/models/achievement.dart';

final achievementsProvider = FutureProvider<List<AchievementModel>>((ref) {
  return ref.watch(userRepositoryProvider).getAchievements();
});
