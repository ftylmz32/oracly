/// Profile must not resurrect Premium entitlement after demote.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/domain/models/user_profile.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('profile save does not rewrite or_premium_active', () async {
    SharedPreferences.setMockInitialValues({'or_premium_active': false});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final users = MockUserRepository(storage);
    await users.saveProfile(
      const UserProfileModel(name: 'Fatih', isPremium: true),
    );
    expect(storage.getBool('or_premium_active'), isFalse);
    final profile = await users.getProfile();
    expect(profile.name, 'Fatih');
    expect(profile.isPremium, isFalse);
  });

  test('demote clears plan index so activePlan is null', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final premium = MockPremiumRepository(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    expect(await premium.activePlan(), PremiumPlanKind.yearly);
    await premium.clearLocalPremiumAccess();
    expect(premium.isActiveNow, isFalse);
    expect(await premium.activePlan(), isNull);
    expect(storage.getInt(MockPremiumRepository.planKey), isNull);
  });
}
