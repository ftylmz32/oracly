/// Account wipe must clear all user-bound Premium cache and purchase credentials.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/core/storage/premium_credential_keys.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(LocalStorage, InMemorySecureStorage, MockPremiumRepository)>
    _fixture() async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorage(await SharedPreferences.getInstance());
  final secure = InMemorySecureStorage();
  final premium = MockPremiumRepository(storage, secureStorage: secure);
  return (storage, secure, premium);
}

Future<void> _seedPremiumWithCredentials(MockPremiumRepository premium) async {
  await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
  await premium.savePurchaseCredentials(
    const PremiumPurchaseCredentials(
      platform: 'android',
      productId: 'oracly_premium_yearly',
      purchaseToken: 'token-user-a',
      transactionId: 'txn-user-a',
    ),
  );
}

void _expectPremiumFullyCleared(
  LocalStorage storage,
  InMemorySecureStorage secure,
  MockPremiumRepository premium,
) {
  expect(premium.isActiveNow, isFalse);
  expect(premium.wasAuthoritativelyVerified, isFalse);
  expect(premium.readPurchaseCredentials(), isNull);
  expect(storage.getBool(MockPremiumRepository.activeKey), isNull);
  expect(storage.getInt(MockPremiumRepository.planKey), isNull);
  expect(storage.getBool(MockPremiumRepository.authoritativeKey), isNull);
  expect(storage.getString(MockPremiumRepository.platformKey), isNull);
  expect(storage.getString(MockPremiumRepository.productIdKey), isNull);
  expect(storage.getString(MockPremiumRepository.purchaseTokenKey), isNull);
  expect(storage.getString(MockPremiumRepository.transactionIdKey), isNull);
  expect(secure.snapshot.containsKey(PremiumCredentialKeys.purchaseToken), isFalse);
  expect(secure.snapshot.containsKey(PremiumCredentialKeys.transactionId), isFalse);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wipe removes Premium active, plan, authoritative, and credentials',
      () async {
    final (storage, secure, premium) = await _fixture();
    await _seedPremiumWithCredentials(premium);
    await storage.setString('settings_language', 'en');
    await storage.setString('unrelated_pref', 'keep-me');

    expect(premium.isActiveNow, isTrue);
    expect(premium.wasAuthoritativelyVerified, isTrue);
    expect(premium.readPurchaseCredentials(), isNotNull);

    await UserLocalDataWipe.run(storage, secureStorage: secure);

    _expectPremiumFullyCleared(storage, secure, premium);
    expect(storage.getString('settings_language'), 'en');
    expect(storage.getString('unrelated_pref'), 'keep-me');
  });

  test(
    'account switch cannot inherit prior user Premium credentials',
    () async {
      final (storage, secure, premium) = await _fixture();
      final isolation = UserLocalDataIsolation(
        storage,
        secureStorage: secure,
      );
      await isolation.onSignedIn('user-a');
      await _seedPremiumWithCredentials(premium);

      await isolation.onSignedIn('user-b');

      _expectPremiumFullyCleared(storage, secure, premium);
      expect(isolation.localOwnerId, 'user-b');
      expect(premium.readPurchaseCredentials()?.purchaseToken, isNull);
    },
  );

  test('clearPersistedLocalState covers prefs and secure credential keys',
      () async {
    final (storage, secure, premium) = await _fixture();
    for (final key in MockPremiumRepository.localUserBoundKeys) {
      await storage.setString(key, 'seed');
    }
    await premium.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: 'prod',
        purchaseToken: 'tok',
        transactionId: 'txn',
      ),
    );

    await MockPremiumRepository.clearPersistedLocalState(
      storage,
      secureStorage: secure,
    );

    for (final key in MockPremiumRepository.localUserBoundKeys) {
      expect(storage.getString(key), isNull, reason: key);
    }
    expect(await secure.read(PremiumCredentialKeys.purchaseToken), isNull);
    expect(await secure.read(PremiumCredentialKeys.transactionId), isNull);
  });
}
