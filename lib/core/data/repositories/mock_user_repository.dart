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
  /// the idempotency contract for [recordReadingCompletion]. Every id ever
  /// recorded stays here for the life of the install; the set only grows.
  static const _readingLedgerIdsKey = 'profile_reading_ledger_ids';

  /// The pre-ledger totalReadings value, captured at most once (the first
  /// time [recordReadingCompletion] ever runs on this install) and never
  /// changed again. totalReadings going forward is always
  /// `_legacyBaseline + ledger.length` — a pure computation with no
  /// separately-incremented counter to drift out of sync with the ledger,
  /// so a crash between writes can only leave the ledger and the baseline
  /// each individually durable; recomputing from them is always correct.
  static const _legacyBaselineKey = 'profile_reading_ledger_legacy_baseline';

  /// Serializes all recordReadingCompletion calls (regardless of id) onto
  /// one queue, so two concurrent callers can never both observe "not yet
  /// recorded" for the same id and each append/increment independently.
  Future<void> _readingLedgerQueue = Future.value();

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
  Future<bool> recordReadingCompletion(String readingId) {
    // Chain onto the queue regardless of whether the previous job threw,
    // so one failed attempt can never block every later one.
    final result = _readingLedgerQueue.then(
      (_) => _recordReadingCompletionLocked(readingId),
    );
    _readingLedgerQueue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<bool> _recordReadingCompletionLocked(String readingId) async {
    final ledger = _storage.getStringList(_readingLedgerIdsKey) ?? const [];
    final alreadyRecorded = ledger.contains(readingId);
    if (!alreadyRecorded) {
      await _storage.setStringList(_readingLedgerIdsKey, [
        ...ledger,
        readingId,
      ]);
    }
    // Captured from whatever totalReadings already held BEFORE this ledger
    // ever contributes — exactly once, ever. A legacy user's existing
    // count becomes the permanent floor; it can only grow from here.
    if (_storage.getInt(_legacyBaselineKey) == null) {
      await _storage.setInt(
        _legacyBaselineKey,
        _storage.getInt(_readingsKey) ?? 0,
      );
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
    final baseline = _storage.getInt(_legacyBaselineKey);
    if (baseline == null) {
      // Ledger has never run on this install — the plain counter (legacy
      // behavior, or 0 for a fresh install) is authoritative until the
      // first recordReadingCompletion call establishes the floor.
      return _storage.getInt(_readingsKey) ?? 0;
    }
    final ledgerCount =
        (_storage.getStringList(_readingLedgerIdsKey) ?? const []).length;
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
