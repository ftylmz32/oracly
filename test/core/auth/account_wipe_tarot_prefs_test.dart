/// Account wipe must clear tarot selection prefs and achievement dates.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe_keys.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_path_provider.dart';

/// Throws when [remove] is called for any key in [failingKeys], then
/// behaves normally for everything else — used to prove wipe cleanup is
/// best-effort PER KEY, not per group: one throwing remove must never
/// stop the loop before it reaches the rest of the keys/prefix set.
class _KeyFailingStorage extends LocalStorage {
  _KeyFailingStorage(SharedPreferences prefs, {required this.failingKeys})
      : super(prefs);

  final Set<String> failingKeys;

  @override
  Future<bool> remove(String key) async {
    if (failingKeys.contains(key)) {
      throw StateError('simulated remove failure for $key');
    }
    return super.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await installTestPathProvider('oracly-tarot-wipe-');
  });

  test('wipe clears deck/spread prefs and fake achievement dates', () async {
    SharedPreferences.setMockInitialValues({
      'or_selected_deck': 'leaked-deck',
      'or_selected_spread': 'three',
      'profile_achievement_dates': '{"first_reading":"2026-08-01T00:00:00.000Z"}',
      'profile_achievements': ['first_reading'],
      'or_review_access_granted': true,
      'coffee_v2_submission': '{}',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    expect(UserLocalDataWipeKeys.profile, contains('or_selected_deck'));
    expect(UserLocalDataWipeKeys.profile, contains('or_selected_spread'));
    final result = await UserLocalDataWipe.run(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    expect(
      result.isComplete,
      isTrue,
      reason: 'nothing was made to fail — the whole wipe must report '
          'complete',
    );
    expect(result.failedOperations, isEmpty);
    expect(storage.getString('or_selected_deck'), isNull);
    expect(storage.getString('or_selected_spread'), isNull);
    expect(storage.getString('profile_achievement_dates'), isNull);
    expect(storage.getBool('or_review_access_granted'), isNull);
    expect(storage.getString('coffee_v2_submission'), isNull);
  });

  test(
      'wipe clears the reading-count ledger AND the legacy baseline — the '
      'ledger is account-scoped state, never left for the next owner',
      () async {
    SharedPreferences.setMockInitialValues({
      'profile_readings': 15,
      'profile_reading_ledger_ids': ['old-a', 'old-b'],
      'profile_reading_ledger_legacy_baseline': 13,
      'profile_achievements': ['first_reading'],
      'or_reading_history': ['old owner reading'],
      'settings_language': 'tr',
      'settings_theme': 'dark',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    expect(
      UserLocalDataWipeKeys.profile,
      contains(MockUserRepository.readingLedgerIdsKey),
    );
    expect(
      UserLocalDataWipeKeys.profile,
      contains(MockUserRepository.legacyBaselineKey),
    );

    final result = await UserLocalDataWipe.run(
      storage,
      secureStorage: InMemorySecureStorage(),
    );

    expect(result.isComplete, isTrue);
    expect(
      storage.getStringList(MockUserRepository.readingLedgerIdsKey),
      isNull,
    );
    expect(storage.getInt(MockUserRepository.legacyBaselineKey), isNull);
    expect(storage.getInt('profile_readings'), isNull);
    expect(storage.getStringList('or_reading_history'), isEmpty);
    expect(storage.getStringList('profile_achievements'), isNull);

    // Device-scoped settings must never be touched by an account-scoped
    // wipe.
    expect(storage.getString('settings_language'), 'tr');
    expect(storage.getString('settings_theme'), 'dark');
  });

  test(
      'a throwing remove for an EARLIER profile key must not stop the '
      'loop before it reaches the reading-count ledger, baseline, or any '
      'other later key — cleanup is best-effort PER KEY, not per group',
      () async {
    SharedPreferences.setMockInitialValues({
      'profile_name': 'Ada',
      // profile_spiritual sits BEFORE the ledger keys in
      // UserLocalDataWipeKeys.profile — its remove is made to throw.
      'profile_spiritual': 0.5,
      'profile_readings': 15,
      'profile_reading_ledger_ids': ['owner-a-r1'],
      'profile_reading_ledger_legacy_baseline': 5,
      'profile_achievements': ['first_reading'],
      'or_selected_deck': 'leaked-deck',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = _KeyFailingStorage(
      prefs,
      failingKeys: {'profile_spiritual'},
    );

    // The whole run must still complete without throwing — the outer
    // step() boundary in UserLocalDataWipe.run already guarantees this;
    // what this test actually proves is what happens AFTER that one
    // failure, inside the same key-clearing pass.
    final result = await UserLocalDataWipe.run(
      storage,
      secureStorage: InMemorySecureStorage(),
    );

    expect(
      result.isComplete,
      isFalse,
      reason: 'one mandatory key failed — the result must say so honestly',
    );
    expect(result.failedOperations, contains('profile_spiritual'));
    expect(
      result.failedOperations,
      isNot(contains(MockUserRepository.readingLedgerIdsKey)),
      reason: 'the ledger key itself succeeded — it must not be reported '
          'as failed',
    );
    expect(
      result.failedOperations,
      isNot(contains(MockUserRepository.legacyBaselineKey)),
    );

    // The deliberately failing key may remain — that part of the
    // contract is unchanged.
    expect(storage.getDouble('profile_spiritual'), 0.5);

    // Every key positioned AFTER the failing one in the SAME list must
    // still have been attempted and cleared.
    expect(storage.getInt('profile_readings'), isNull);
    expect(storage.getStringList('profile_achievements'), isNull);
    expect(storage.getString('or_selected_deck'), isNull);
    expect(
      storage.getStringList(MockUserRepository.readingLedgerIdsKey),
      isNull,
      reason: 'the reading ledger sits AFTER the injected failure — it '
          'must still be reached and cleared',
    );
    expect(
      storage.getInt(MockUserRepository.legacyBaselineKey),
      isNull,
      reason: 'the legacy baseline sits AFTER the injected failure — it '
          'must still be reached and cleared',
    );
    // A key positioned BEFORE the failing one must be entirely unaffected
    // by a LATER key's own failure not applying here — sanity check that
    // normal keys still clear too.
    expect(storage.getString('profile_name'), isNull);
  });

  test(
      'a throwing remove for one key inside a PREFIXED set must not stop '
      'the rest of that same prefix from being cleared', () async {
    SharedPreferences.setMockInitialValues({
      'content_favorites_a': 'a',
      'content_favorites_b': 'b',
      'content_favorites_c': 'c',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = _KeyFailingStorage(
      prefs,
      failingKeys: {'content_favorites_b'},
    );

    final result = await UserLocalDataWipe.run(
      storage,
      secureStorage: InMemorySecureStorage(),
    );

    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains('content_favorites_b'));
    expect(storage.getString('content_favorites_a'), isNull);
    expect(
      storage.getString('content_favorites_b'),
      'b',
      reason: 'this key\'s own remove failed — it may remain',
    );
    expect(
      storage.getString('content_favorites_c'),
      isNull,
      reason: 'a sibling key in the SAME prefix set failing must not '
          'prevent this one from still being attempted and cleared',
    );
  });

  test('achievement unlock records real UTC timestamp', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final users = MockUserRepository(storage);
    final before = DateTime.now().toUtc().subtract(const Duration(seconds: 2));
    await users.unlockAchievement('first_reading');
    final after = DateTime.now().toUtc().add(const Duration(seconds: 2));
    final list = await users.getAchievements();
    final unlocked = list.firstWhere((a) => a.key == 'first_reading');
    expect(unlocked.unlocked, isTrue);
    expect(unlocked.unlockedAt, isNotNull);
    expect(unlocked.unlockedAt!.isAfter(before), isTrue);
    expect(unlocked.unlockedAt!.isBefore(after), isTrue);
    expect(unlocked.unlockedAt, isNot(DateTime(2026, 8, 1)));
  });
}
