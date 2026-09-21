/// Local user profile repository — SharedPreferences-backed (legacy "Mock" name).
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../domain/models/achievement.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local_storage.dart';

class MockUserRepository implements UserRepository {
  MockUserRepository(this._storage);

  final LocalStorage _storage;

  static const _nameKey = 'profile_name';
  static const _jobKey = 'profile_job';
  static const _interestsKey = 'profile_interests';
  static const _goalsKey = 'profile_goals';
  static const _streakKey = 'profile_streak';
  static const _readingsKey = 'profile_readings';
  static const _spiritKey = 'profile_spiritual';
  static const _deckKey = 'profile_favorite_deck';
  static const _premiumKey = 'or_premium_active';
  static const _achievementsKey = 'profile_achievements';
  static const _achievementDatesKey = 'profile_achievement_dates';

  /// Durable ledger of reading ids already recorded toward totalReadings —
  /// the idempotency contract for [recordReadingCompletion]. Seeded once by
  /// [ensureReadingCompletionMigration] with whatever stable ids History
  /// already retained BEFORE the ledger existed (so replaying one of THOSE
  /// never double-counts), then grows by exactly one entry per genuinely
  /// new reading from then on. Every id ever recorded stays here for the
  /// life of the install; the set only grows.
  ///
  /// PUBLIC and referenced directly by [UserLocalDataWipeKeys.profile] —
  /// this is account-scoped state. A new owner on the same device must
  /// never inherit a prior owner's reading ledger; the canonical wipe
  /// contract is the single source of truth for what "account-scoped"
  /// means, so it must always be able to name this key without a second,
  /// independently-maintained string literal drifting out of sync.
  static const readingLedgerIdsKey = 'profile_reading_ledger_ids';

  /// The RESIDUAL legacy totalReadings value — set at most once, by
  /// [ensureReadingCompletionMigration], and never changed again.
  /// totalReadings going forward is always `legacyBaseline +
  /// ledger.length`: a pure computation with no separately-incremented
  /// counter to drift out of sync with the ledger, so a crash between
  /// writes can only leave the ledger and the baseline each individually
  /// durable; recomputing from them is always correct. "Residual" because
  /// migration may seed the ledger with KNOWN legacy ids up front — the
  /// baseline is only the part of the old lifetime count NOT already
  /// represented by one of those known ids (see
  /// [ensureReadingCompletionMigration]).
  ///
  /// PUBLIC for the same reason as [readingLedgerIdsKey] — account-scoped,
  /// and named directly by the canonical wipe contract.
  static const legacyBaselineKey = 'profile_reading_ledger_legacy_baseline';

  /// Serializes migration and every recordReadingCompletion call (regardless
  /// of id) onto one queue, so two concurrent callers — including two
  /// concurrent FIRST activations of the migration — can never both
  /// observe "not yet migrated"/"not yet recorded" and each act
  /// independently.
  Future<void> _readingLedgerQueue = Future.value();

  Future<T> _enqueueReadingLedgerJob<T>(Future<T> Function() job) {
    final result = _readingLedgerQueue.then((_) => job());
    // Chain onto the queue regardless of whether this job threw, so one
    // failed attempt can never block every later one.
    _readingLedgerQueue = result.then((_) {}, onError: (_) {});
    return result;
  }

  static const _achievementDefs = [
    ('first_reading', 'İlk Açılım', 'İlk tarot açılımını tamamladın.',
        Icons.auto_awesome_rounded),
    ('cards_100', '100 Kart', '100 kart keşfettin.', Icons.style_rounded),
    ('first_premium', 'İlk Premium', 'OR Premium ailesine katıldın.',
        Icons.workspace_premium_rounded),
  ];

  @override
  Future<UserProfileModel> getProfile() async {
    return UserProfileModel(
      name: _storage.getString(_nameKey) ?? '',
      job: _storage.getString(_jobKey) ?? '',
      interests: _storage.getStringList(_interestsKey) ?? [],
      goals: _storage.getStringList(_goalsKey) ?? [],
      currentStreak: _storage.getInt(_streakKey) ?? 0,
      totalReadings: _computeTotalReadings(),
      spiritualLevel: _storage.getDouble(_spiritKey) ?? 0.0,
      favoriteDeckId: _storage.getString(_deckKey) ?? 'classic',
      isPremium: _storage.getBool(_premiumKey) ?? false,
      unlockedAchievementKeys:
          _storage.getStringList(_achievementsKey) ?? const [],
    );
  }

  @override
  Future<void> saveProfile(UserProfileModel profile) async {
    await _storage.setString(_nameKey, profile.name);
    await _storage.setString('user_name', profile.name);
    await _storage.setString(_jobKey, profile.job);
    await _storage.setStringList(_interestsKey, profile.interests);
    await _storage.setStringList(_goalsKey, profile.goals);
    await _storage.setInt(_streakKey, profile.currentStreak);
    await _storage.setInt(_readingsKey, profile.totalReadings);
    await _storage.setDouble(_spiritKey, profile.spiritualLevel);
    await _storage.setString(_deckKey, profile.favoriteDeckId);
    // Never write Premium from profile saves — MockPremiumRepository owns
    // `or_premium_active`. A stale UserProfileModel.isPremium must not
    // resurrect entitlement after authoritative demote.
    await _storage.setStringList(
      _achievementsKey,
      profile.unlockedAchievementKeys,
    );
  }

  @override
  Future<List<AchievementModel>> getAchievements() async {
    final profile = await getProfile();
    final keys = profile.unlockedAchievementKeys.toSet();
    final dates = _achievementDates();
    return _achievementDefs
        .map(
          (d) => AchievementModel(
            key: d.$1,
            title: d.$2,
            description: d.$3,
            icon: d.$4,
            unlocked: keys.contains(d.$1),
            unlockedAt: keys.contains(d.$1) ? dates[d.$1] : null,
          ),
        )
        .toList();
  }

  @override
  Future<void> unlockAchievement(String key) async {
    final profile = await getProfile();
    if (profile.unlockedAchievementKeys.contains(key)) return;
    final dates = _achievementDates();
    dates[key] = DateTime.now().toUtc();
    await _storage.setString(_achievementDatesKey, jsonEncode({
      for (final e in dates.entries) e.key: e.value.toIso8601String(),
    }));
    await saveProfile(
      profile.copyWith(
        unlockedAchievementKeys: [...profile.unlockedAchievementKeys, key],
      ),
    );
  }

  @override
  Future<void> incrementStreak() async {
    final profile = await getProfile();
    await saveProfile(
      profile.copyWith(currentStreak: profile.currentStreak + 1),
    );
  }

  @override
  Future<void> ensureReadingCompletionMigration(
    List<String> existingHistoryIds,
  ) {
    return _enqueueReadingLedgerJob(
      () => _ensureMigrationLocked(existingHistoryIds),
    );
  }

  /// One-time reconciliation between the pre-ledger totalReadings counter
  /// and the stable reading ids History already retained at the moment
  /// the ledger activates. No-ops instantly once migration has already run
  /// (baseline non-null) — safe and cheap to call on every save.
  ///
  /// Without this, a legacy history row already counted in the OLD
  /// `profile_readings` value would look "unknown" to the new ledger the
  /// first time it's ever replayed (e.g. an old reading resurfacing
  /// through a retry or a version-seed path) and would be counted a
  /// SECOND time — a migration double-count.
  ///
  /// Policy for [existingHistoryIds].length vs the legacy total (documented
  /// per the required test matrix):
  /// - legacy total >= known ids: `residualBaseline = legacyTotal -
  ///   knownIds.length`; post-migration total is unchanged
  ///   (`residualBaseline + knownIds.length == legacyTotal`).
  /// - legacy total < known ids (an inconsistent legacy fixture — History
  ///   somehow retained MORE distinct stable ids than the counter ever
  ///   recorded): `residualBaseline = 0`; post-migration total becomes
  ///   `knownIds.length` — i.e. `max(legacyTotal, knownIds.length)`. The
  ///   lifetime count is NEVER decreased, and it is also never allowed to
  ///   under-count more real, distinct history rows than are already on
  ///   disk.
  Future<void> _ensureMigrationLocked(List<String> existingHistoryIds) async {
    if (_storage.getInt(legacyBaselineKey) != null) return;
    final legacyTotal = _storage.getInt(_readingsKey) ?? 0;
    final knownIds = existingHistoryIds.toSet().toList();
    final residualBaseline =
        legacyTotal > knownIds.length ? legacyTotal - knownIds.length : 0;
    // Ledger write FIRST: if the process dies right after this line, the
    // baseline below is still null, so a retry re-enters this same method
    // (the guard above does not short-circuit) and safely re-writes both
    // with the same inputs — never double counts, never loses the seed.
    // The opposite order (baseline first) would risk the guard above
    // treating migration as "done" while the known ids were never
    // actually seeded, which none of the ledger-based math is safe under.
    await _storage.setStringList(readingLedgerIdsKey, knownIds);
    await _storage.setInt(legacyBaselineKey, residualBaseline);
  }

  @override
  Future<bool> recordReadingCompletion(String readingId) {
    return _enqueueReadingLedgerJob(
      () => _recordReadingCompletionLocked(readingId),
    );
  }

  Future<bool> _recordReadingCompletionLocked(String readingId) async {
    // Defense in depth for a caller that records completion without ever
    // calling ensureReadingCompletionMigration first (the real
    // ReadingService flow always does) — treats the legacy counter as the
    // whole floor with no known legacy ids, matching the pre-migration
    // fallback this class always had.
    if (_storage.getInt(legacyBaselineKey) == null) {
      await _ensureMigrationLocked(const []);
    }
    final ledger = _storage.getStringList(readingLedgerIdsKey) ?? const [];
    final alreadyRecorded = ledger.contains(readingId);
    if (!alreadyRecorded) {
      await _storage.setStringList(readingLedgerIdsKey, [
        ...ledger,
        readingId,
      ]);
    }
    final total = _computeTotalReadings();
    // Mirror the computed total into the plain int key for legacy direct
    // readers (e.g. settings snapshots) — best-effort; getProfile() never
    // trusts this value once the ledger is active, only the computation.
    await _storage.setInt(_readingsKey, total);
    if (total >= 1) await unlockAchievement('first_reading');
    if (total >= 100) await unlockAchievement('cards_100');
    return !alreadyRecorded;
  }

  int _computeTotalReadings() {
    final baseline = _storage.getInt(legacyBaselineKey);
    if (baseline == null) {
      // Migration has never run on this install — the plain counter
      // (legacy behavior, or 0 for a fresh install) is authoritative until
      // the first ensureReadingCompletionMigration/recordReadingCompletion
      // call establishes the floor.
      return _storage.getInt(_readingsKey) ?? 0;
    }
    final ledgerCount =
        (_storage.getStringList(readingLedgerIdsKey) ?? const []).length;
    return baseline + ledgerCount;
  }

  Map<String, DateTime> _achievementDates() {
    final raw = _storage.getString(_achievementDatesKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return {};
      final out = <String, DateTime>{};
      for (final e in json.entries) {
        final parsed = DateTime.tryParse('${e.value}');
        if (parsed != null) out['${e.key}'] = parsed.toUtc();
      }
      return out;
    } catch (_) {
      return {};
    }
  }
}
