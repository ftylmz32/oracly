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

  /// One-time reconciliation between any pre-existing totalReadings value
  /// and the stable reading ids History already retains. Must run (or
  /// have already run) before [recordReadingCompletion] can be trusted for
  /// an install that has real history predating the idempotency ledger —
  /// otherwise replaying one of those already-counted legacy ids would
  /// double count it. Idempotent: a no-op once migration has already run
  /// for this install, so callers may call it unconditionally on every
  /// save. [existingHistoryIds] must be gathered BEFORE the incoming
  /// reading is saved, so a genuinely new reading is never mistaken for
  /// a pre-existing legacy one.
  Future<void> ensureReadingCompletionMigration(
    List<String> existingHistoryIds,
  );

  /// Records that [readingId] should contribute to totalReadings.
  ///
  /// Idempotent and concurrency-safe: the SAME [readingId] may be passed
  /// any number of times — sequential retry, two concurrent callers for
  /// the same session, or a replay after a process restart — and
  /// totalReadings advances by AT MOST ONE for it. Distinct ids each
  /// contribute their own +1. A legacy id already known to
  /// [ensureReadingCompletionMigration] contributes +0 — it was already
  /// represented in the pre-migration total. Implementations must never
  /// lose a contribution to a partial write failure (a crash between
  /// internal writes must self-correct on the next call, not double count
  /// or silently drop the increment).
  ///
  /// Returns true iff this call was the one that actually contributed
  /// (false when [readingId] had already been recorded previously).
  Future<bool> recordReadingCompletion(String readingId);
}
