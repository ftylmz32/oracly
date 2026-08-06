/// OR-1130 — Achievement repository interface.
library;

import '../models/achievement.dart';

abstract class AchievementRepository {
  Future<List<AchievementModel>> getAll();
  Future<void> unlock(String key);
  Future<void> sync();
}
