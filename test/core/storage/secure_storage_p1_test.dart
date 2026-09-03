/// Real secure storage P1 — platform contract, migration, wipe semantics.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_entitlement_reconciler.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/core/storage/legacy_secure_storage_migration.dart';
import 'package:oracly_new/core/storage/premium_credential_keys.dart';
import 'package:oracly_new/core/storage/premium_credential_migration.dart';
import 'package:oracly_new/core/storage/secure_storage_bootstrap.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InactiveVerifier implements PremiumEntitlementVerifier {
  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async =>
      PremiumVerifyResult.inactive('test');
}

Future<(LocalStorage, InMemorySecureStorage)> _open([
  Map<String, Object> seed = const {},
]) async {
  SharedPreferences.setMockInitialValues(seed);
  final storage = LocalStorage(await SharedPreferences.getInstance());
  return (storage, InMemorySecureStorage());
}

MockPremiumRepository _premium(
  LocalStorage storage,
  InMemorySecureStorage secure,
) =>
    MockPremiumRepository(storage, secureStorage: secure);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('write read delete secure value', () async {
    final secure = InMemorySecureStorage();
    await secure.write('k', 'v');
    expect(await secure.read('k'), 'v');
    await secure.delete('k');
    expect(await secure.read('k'), isNull);
  });

  test('deleteAll clears secure storage', () async {
    final secure = InMemorySecureStorage();
    await secure.write('a', '1');
    await secure.write('b', '2');
    await secure.deleteAll();
    expect(secure.snapshot, isEmpty);
  });

  test('legacy premium credential migration is idempotent', () async {
    final (storage, secure) = await _open();
    await storage.setString(MockPremiumRepository.purchaseTokenKey, 'legacy-token');
    await storage.setString(MockPremiumRepository.transactionIdKey, 'legacy-txn');
    await storage.setString(MockPremiumRepository.platformKey, 'android');
    await storage.setString(MockPremiumRepository.productIdKey, 'prod');

    await PremiumCredentialMigration.migrateIfNeeded(storage, secure);
    expect(await secure.read(PremiumCredentialKeys.purchaseToken), 'legacy-token');
    expect(await secure.read(PremiumCredentialKeys.transactionId), 'legacy-txn');
    expect(storage.getString(MockPremiumRepository.purchaseTokenKey), isNull);
    expect(storage.getString(MockPremiumRepository.transactionIdKey), isNull);

    await PremiumCredentialMigration.migrateIfNeeded(storage, secure);
    expect(await secure.read(PremiumCredentialKeys.purchaseToken), 'legacy-token');
  });

  test('interrupted migration recovers safely', () async {
    final (storage, secure) = await _open();
    await storage.setString(MockPremiumRepository.purchaseTokenKey, 'tok');
    await secure.write(PremiumCredentialKeys.purchaseToken, 'tok');

    await PremiumCredentialMigration.migrateIfNeeded(storage, secure);

    expect(storage.getString(MockPremiumRepository.purchaseTokenKey), isNull);
    expect(storage.getBool(PremiumCredentialMigration.doneKey), isTrue);
  });

  test('legacy auth secure_* migration moves tokens off SharedPreferences', () async {
    final (storage, secure) = await _open();
    final encoded = base64Encode(utf8.encode('access-token'));
    await storage.setString('secure_auth_access_token', encoded);

    await LegacySecureStorageMigration.runIfNeeded(storage, secure);

    expect(await secure.read('auth_access_token'), 'access-token');
    expect(storage.getString('secure_auth_access_token'), isNull);
    expect(storage.getBool('or_secure_storage_migrated_v1'), isTrue);
  });

  test('savePurchaseCredentials stores secrets only in secure storage', () async {
    final (storage, secure) = await _open();
    final premium = _premium(storage, secure);
    await premium.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: 'app.oracly.premium.yearly',
        purchaseToken: 'secret-token',
        transactionId: 'txn-1',
      ),
    );

    expect(storage.getString(MockPremiumRepository.purchaseTokenKey), isNull);
    expect(storage.getString(MockPremiumRepository.transactionIdKey), isNull);
    expect(await secure.read(PremiumCredentialKeys.purchaseToken), 'secret-token');
    expect(await secure.read(PremiumCredentialKeys.transactionId), 'txn-1');
    expect(premium.readPurchaseCredentials()?.purchaseToken, 'secret-token');
  });

  test('warmCredentialCache loads migrated legacy credentials', () async {
    final (storage, secure) = await _open({
      MockPremiumRepository.purchaseTokenKey: 'legacy',
      MockPremiumRepository.platformKey: 'android',
      MockPremiumRepository.productIdKey: 'prod',
    });
    final premium = _premium(storage, secure);
    await premium.warmCredentialCache();
    expect(premium.readPurchaseCredentials()?.purchaseToken, 'legacy');
    expect(storage.getString(MockPremiumRepository.purchaseTokenKey), isNull);
  });

  test('account switch wipes secure premium credentials', () async {
    final (storage, secure) = await _open();
    final premium = _premium(storage, secure);
    await premium.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: 'prod',
        purchaseToken: 'token-user-a',
        transactionId: 'txn-user-a',
      ),
    );

    final isolation = UserLocalDataIsolation(
      storage,
      secureStorage: secure,
    );
    await isolation.onSignedIn('user-a');
    await isolation.onSignedIn('user-b');

    expect(premium.readPurchaseCredentials(), isNull);
    expect(await secure.read(PremiumCredentialKeys.purchaseToken), isNull);
    expect(storage.getString(MockPremiumRepository.purchaseTokenKey), isNull);
  });

  test('account deletion wipe clears secure credentials', () async {
    final (storage, secure) = await _open();
    final premium = _premium(storage, secure);
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    await premium.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: 'prod',
        purchaseToken: 'tok-del',
        transactionId: 'txn-del',
      ),
    );

    await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(premium.isActiveNow, isFalse);
    expect(premium.readPurchaseCredentials(), isNull);
    expect(await secure.read(PremiumCredentialKeys.purchaseToken), isNull);
    expect(storage.getString(MockPremiumRepository.purchaseTokenKey), isNull);
  });

  test('Premium still requires authoritative verification after restart cache',
      () async {
    final (storage, secure) = await _open();
    final premium = _premium(storage, secure);
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    await premium.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: 'prod',
        purchaseToken: 'token',
      ),
    );
    await premium.warmCredentialCache();

    final reconciler = PremiumEntitlementReconciler(
      premium: premium,
      purchaseConfigured: true,
      verifier: _InactiveVerifier(),
      forceReleaseMode: true,
    );
    await reconciler.reconcile();

    expect(premium.isActiveNow, isFalse);
    expect(premium.readPurchaseCredentials()?.purchaseToken, 'token');
  });

  test('SecureStorageBootstrap runs both migrations once', () async {
    final (storage, secure) = await _open({
      MockPremiumRepository.purchaseTokenKey: 'tok',
      'secure_auth_refresh_token': base64Encode(utf8.encode('refresh')),
    });

    await SecureStorageBootstrap.run(storage, secure);

    expect(storage.getString(MockPremiumRepository.purchaseTokenKey), isNull);
    expect(storage.getString('secure_auth_refresh_token'), isNull);
    expect(await secure.read(PremiumCredentialKeys.purchaseToken), 'tok');
    expect(await secure.read('auth_refresh_token'), 'refresh');
  });
}
