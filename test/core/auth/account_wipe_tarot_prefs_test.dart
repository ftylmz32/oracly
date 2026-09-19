/// Account wipe must clear tarot selection prefs and achievement dates.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe_keys.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wipe clears deck/spread prefs and fake achievement dates', () async {
    SharedPreferences.setMockInitialValues({
      'or_selected_deck': 'leaked-deck',
      'or_selected_spread': 'three',
      'profile_achievement_dates': '{"first_reading":"2026-08-01T00:00:00.000Z"}',
      'profile_achievements': ['first_reading'],
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    expect(UserLocalDataWipeKeys.profile, contains('or_selected_deck'));
    expect(UserLocalDataWipeKeys.profile, contains('or_selected_spread'));
    await UserLocalDataWipe.run(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    expect(storage.getString('or_selected_deck'), isNull);
    expect(storage.getString('or_selected_spread'), isNull);
    expect(storage.getString('profile_achievement_dates'), isNull);
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
