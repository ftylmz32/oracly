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

  /// Records that [readingId] should contribute to totalReadings.
  ///
  /// Idempotent and concurrency-safe: the SAME [readingId] may be passed
  /// any number of times — sequential retry, two concurrent callers for
  /// the same session, or a replay after a process restart — and
  /// totalReadings advances by AT MOST ONE for it. Distinct ids each
  /// contribute their own +1. Implementations must never lose a
  /// contribution to a partial write failure (a crash between internal
  /// writes must self-correct on the next call, not double count or
  /// silently drop the increment).
  ///
  /// Returns true iff this call was the one that actually contributed
  /// (false when [readingId] had already been recorded previously).
  Future<bool> recordReadingCompletion(String readingId);
}
