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
import '../datasources/storage_result.dart';

class MockPremiumRepository implements PremiumRepository {
  MockPremiumRepository(
    this._storage, {
    SecureStorage? secureStorage,
    bool Function()? ownerAccessAllowed,
  }) : _secure = secureStorage ?? InMemorySecureStorage(),
       _ownerAccessAllowed = ownerAccessAllowed;

  final LocalStorage _storage;
  final SecureStorage _secure;
  final bool Function()? _ownerAccessAllowed;

  bool get _ownerAllowed => _ownerAccessAllowed?.call() ?? true;

  void _requireOwnerAccess() {
    if (!_ownerAllowed) {
      throw StateError('premium owner boundary not isolated');
    }
  }

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
  /// Account-boundary wipe — used only by [UserLocalDataWipe]. A `false`
  /// (non-throwing) removal is exactly as much a failure here as a thrown
  /// one, so it throws to let the wipe's per-step failure tracking catch
  /// it the same way; every other key is still attempted regardless.
  static Future<void> clearPersistedLocalState(
    LocalStorage storage, {
    required SecureStorage secureStorage,
  }) async {
    final failed = <String>[];
    Future<void> removeKey(String key) async {
      try {
        if (!await storage.remove(key)) failed.add(key);
      } catch (_) {
        failed.add(key);
      }
    }

    for (final key in localUserBoundKeys) {
      await removeKey(key);
    }
    await removeKey(PremiumCredentialMigration.doneKey);
    try {
      await secureStorage.delete(PremiumCredentialKeys.purchaseToken);
    } catch (_) {
      failed.add('secure:${PremiumCredentialKeys.purchaseToken}');
    }
    try {
      await secureStorage.delete(PremiumCredentialKeys.transactionId);
    } catch (_) {
      failed.add('secure:${PremiumCredentialKeys.transactionId}');
    }
    for (final key in legacyCredentialPrefKeys) {
      await removeKey(key);
    }
    if (failed.isNotEmpty) {
      throw StateError('premium local state keys not removed: $failed');
    }
  }

  @override
  Future<bool> isPremiumActive() async => isActiveNow;

  @override
  bool get isActiveNow =>
      _ownerAllowed && (_storage.getBool(activeKey) ?? false);

  @override
  bool get wasAuthoritativelyVerified =>
      _ownerAllowed && (_storage.getBool(authoritativeKey) ?? false);

  @override
  Future<PremiumPlanKind?> activePlan() async {
    if (!_ownerAllowed || !isActiveNow) return null;
    final index = _storage.getInt(planKey);
    if (index == null) return null;
    return PremiumPlanKind.values[index.clamp(0, 2)];
  }

  @override
  Future<void> activatePlan(
    PremiumPlanKind plan, {
    bool authoritative = false,
  }) async {
    _requireOwnerAccess();
    // Commit marker LAST. A partial write may leave harmless metadata behind,
    // but must never expose active Premium before plan + authority are durable.
    try {
      await _storage.setInt(planKey, plan.index).requireDurable(planKey);
      await _storage
          .setBool(authoritativeKey, authoritative)
          .requireDurable(authoritativeKey);
      await _storage.setBool(activeKey, true).requireDurable(activeKey);
    } catch (_) {
      // Fail closed. Best-effort rollback never turns a failed commit into
      // active access; the original persistence error is still rethrown.
      try {
        await _storage.setBool(activeKey, false).requireDurable(activeKey);
      } catch (_) {}
      try {
        await _storage
            .setBool(authoritativeKey, false)
            .requireDurable(authoritativeKey);
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<void> clearLocalPremiumAccess() async {
    _requireOwnerAccess();
    // Active=false is the revocation commit marker and must land first.
    await _storage.setBool(activeKey, false).requireDurable(activeKey);
    await _storage
        .setBool(authoritativeKey, false)
        .requireDurable(authoritativeKey);
    await _storage.remove(planKey).requireDurable(planKey);
  }

  @override
  Future<void> savePurchaseCredentials(
    PremiumPurchaseCredentials credentials,
  ) async {
    _requireOwnerAccess();
    // Secure proof first, discoverable metadata second. Callers activate the
    // entitlement only AFTER this method succeeds.
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

    try {
      await _storage
          .setString(platformKey, credentials.platform)
          .requireDurable(platformKey);
      await _storage
          .setString(productIdKey, credentials.productId)
          .requireDurable(productIdKey);
    } catch (_) {
      // Incomplete metadata must not be mistaken for a usable credential set.
      try {
        await _storage.remove(platformKey).requireDurable(platformKey);
      } catch (_) {}
      try {
        await _storage.remove(productIdKey).requireDurable(productIdKey);
      } catch (_) {}
      _credentialCache = null;
      _credentialsLoaded = false;
      rethrow;
    }

    // Legacy plaintext cleanup is security hygiene, not the commit marker for
    // this already-secure credential. Do not invalidate a verified purchase
    // solely because obsolete plaintext removal failed.
    for (final key in legacyCredentialPrefKeys) {
      try {
        await _storage.remove(key);
      } catch (_) {}
    }
    _credentialCache = credentials;
    _credentialsLoaded = true;
  }

  @override
  Future<PremiumPurchaseCredentials?> readPurchaseCredentials() async {
    if (!_ownerAllowed) return null;
    final platform = _storage.getString(platformKey);
    final productId = _storage.getString(productIdKey);
    if (platform == null || productId == null) {
      _credentialCache = null;
      _credentialsLoaded = false;
      return null;
    }
    if (!_credentialsLoaded) {
      // A fresh instance (e.g. right after app restart) may be asked to
      // reconcile before `warmCredentialCache()` has finished its async
      // secure-storage read. Await it here rather than falling through to
      // the legacy-plaintext-only path below, which is empty for any
      // credential saved after migration (savePurchaseCredentials deletes
      // the legacy keys) -- treating that as "missing" would wrongly wipe
      // a real, previously-authoritatively-verified grant without ever
      // asking the server again.
      await _reloadCredentialCache();
      _credentialsLoaded = true;
    }
    if (_credentialCache != null) return _credentialCache;

    // Pre-migration only: legacy plaintext input before bootstrap ever ran.
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
