/// Local premium repository — cache only; never proves store entitlement.
library;

import '../../../features/premium/models/premium_purchase_credentials.dart';
import '../../copy/premium_copy.dart';
import '../../domain/models/premium_plan.dart';
import '../../domain/repositories/premium_repository.dart';
import '../../storage/in_memory_secure_storage.dart';
import '../../storage/premium_credential_keys.dart';
import '../../storage/premium_credential_migration.dart';
import '../../storage/secure_storage.dart';
import '../datasources/local_storage.dart';

class MockPremiumRepository implements PremiumRepository {
  MockPremiumRepository(
    this._storage, {
    SecureStorage? secureStorage,
  }) : _secure = secureStorage ?? InMemorySecureStorage();

  final LocalStorage _storage;
  final SecureStorage _secure;

  PremiumPurchaseCredentials? _credentialCache;
  bool _credentialsLoaded = false;

  /// Canonical local Premium cache keys (user-bound, non-secret).
  static const activeKey = 'or_premium_active';
  static const planKey = 'or_premium_plan';
  static const authoritativeKey = 'or_premium_authoritative';
  static const platformKey = 'or_premium_platform';
  static const productIdKey = 'or_premium_product_id';

  /// Legacy plaintext credential keys — migrated into secure storage only.
  static const purchaseTokenKey = 'or_premium_purchase_token';
  static const transactionIdKey = 'or_premium_transaction_id';

  static const legacyCredentialPrefKeys = <String>[
    purchaseTokenKey,
    transactionIdKey,
  ];

  /// Every user-bound Premium persistence key in SharedPreferences.
  static const localUserBoundKeys = <String>[
    activeKey,
    planKey,
    authoritativeKey,
    platformKey,
    productIdKey,
  ];

  SecureStorage get secureStorage => _secure;

  /// Loads secure credentials after migration — call during app bootstrap.
  Future<void> warmCredentialCache() async {
    await PremiumCredentialMigration.migrateIfNeeded(_storage, _secure);
    await _reloadCredentialCache();
    _credentialsLoaded = true;
  }

  /// Removes all local Premium entitlement cache and secure credentials.
  static Future<void> clearPersistedLocalState(
    LocalStorage storage, {
    required SecureStorage secureStorage,
  }) async {
    for (final key in localUserBoundKeys) {
      await storage.remove(key);
    }
    await storage.remove(PremiumCredentialMigration.doneKey);
    await secureStorage.delete(PremiumCredentialKeys.purchaseToken);
    await secureStorage.delete(PremiumCredentialKeys.transactionId);
    for (final key in legacyCredentialPrefKeys) {
      await storage.remove(key);
    }
  }

  @override
  Future<bool> isPremiumActive() async => isActiveNow;

  @override
  bool get isActiveNow => _storage.getBool(activeKey) ?? false;

  @override
  bool get wasAuthoritativelyVerified =>
      _storage.getBool(authoritativeKey) ?? false;

  @override
  Future<PremiumPlanKind?> activePlan() async {
    final index = _storage.getInt(planKey);
    if (index == null) return null;
    return PremiumPlanKind.values[index.clamp(0, 2)];
  }

  @override
  Future<void> activatePlan(
    PremiumPlanKind plan, {
    bool authoritative = false,
  }) async {
    await _storage.setBool(activeKey, true);
    await _storage.setInt(planKey, plan.index);
    await _storage.setBool(authoritativeKey, authoritative);
  }

  @override
  Future<void> clearLocalPremiumAccess() async {
    await _storage.setBool(activeKey, false);
    await _storage.setBool(authoritativeKey, false);
  }

  @override
  Future<void> savePurchaseCredentials(
    PremiumPurchaseCredentials credentials,
  ) async {
    await _storage.setString(platformKey, credentials.platform);
    await _storage.setString(productIdKey, credentials.productId);
    await _secure.write(
      PremiumCredentialKeys.purchaseToken,
      credentials.purchaseToken,
    );
    if (credentials.transactionId != null &&
        credentials.transactionId!.trim().isNotEmpty) {
      await _secure.write(
        PremiumCredentialKeys.transactionId,
        credentials.transactionId!,
      );
    } else {
      await _secure.delete(PremiumCredentialKeys.transactionId);
    }
    for (final key in legacyCredentialPrefKeys) {
      await _storage.remove(key);
    }
    _credentialCache = credentials;
    _credentialsLoaded = true;
  }

  @override
  PremiumPurchaseCredentials? readPurchaseCredentials() {
    final platform = _storage.getString(platformKey);
    final productId = _storage.getString(productIdKey);
    if (platform == null || productId == null) {
      _credentialCache = null;
      _credentialsLoaded = false;
      return null;
    }
    if (_credentialsLoaded) return _credentialCache;

    // Pre-migration only: legacy plaintext input before bootstrap runs.
    final legacyToken = _storage.getString(purchaseTokenKey);
    if (legacyToken == null || legacyToken.isEmpty) return null;
    return PremiumPurchaseCredentials(
      platform: platform,
      productId: productId,
      purchaseToken: legacyToken,
      transactionId: _storage.getString(transactionIdKey),
    );
  }

  Future<void> _reloadCredentialCache() async {
    final platform = _storage.getString(platformKey);
    final productId = _storage.getString(productIdKey);
    final token = await _secure.read(PremiumCredentialKeys.purchaseToken);
    if (platform == null || productId == null || token == null || token.isEmpty) {
      _credentialCache = null;
      return;
    }
    final txn = await _secure.read(PremiumCredentialKeys.transactionId);
    _credentialCache = PremiumPurchaseCredentials(
      platform: platform,
      productId: productId,
      purchaseToken: token,
      transactionId: txn,
    );
  }

  @override
  Future<List<PremiumPlanModel>> getPlans() async {
    final active = await activePlan();
    return [
      PremiumPlanModel(
        kind: PremiumPlanKind.monthly,
        label: PremiumCopy.planMonthlyLabel,
        price: PremiumCopy.planPricePending,
        subtitle: PremiumCopy.planMonthlySubtitle,
        isActive: active == PremiumPlanKind.monthly,
      ),
      PremiumPlanModel(
        kind: PremiumPlanKind.yearly,
        label: PremiumCopy.planYearlyLabel,
        price: PremiumCopy.planPricePending,
        subtitle: PremiumCopy.planYearlySubtitle,
        isActive: active == PremiumPlanKind.yearly,
      ),
      PremiumPlanModel(
        kind: PremiumPlanKind.lifetime,
        label: PremiumCopy.planLifetimeLabel,
        price: PremiumCopy.planPricePending,
        subtitle: PremiumCopy.planLifetimeSubtitle,
        isActive: active == PremiumPlanKind.lifetime,
      ),
    ];
  }
}
