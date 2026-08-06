/// OR-1100 — User profile repository interface.
library;

import '../models/achievement.dart';
import '../models/user_profile.dart';

abstract class UserRepository {
  Future<UserProfileModel> getProfile();
  Future<void> saveProfile(UserProfileModel profile);
  Future<List<AchievementModel>> getAchievements();
  Future<void> unlockAchievement(String key);
  Future<void> incrementStreak();
  Future<void> incrementReadings();
}
