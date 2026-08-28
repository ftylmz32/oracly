/// Local premium repository — cache only; never proves store entitlement.
library;

import '../../../features/premium/models/premium_purchase_credentials.dart';
import '../../copy/premium_copy.dart';
import '../../domain/models/premium_plan.dart';
import '../../domain/repositories/premium_repository.dart';
import '../datasources/local_storage.dart';

class MockPremiumRepository implements PremiumRepository {
  MockPremiumRepository(this._storage);

  final LocalStorage _storage;
  static const _premiumKey = 'or_premium_active';
  static const _planKey = 'or_premium_plan';
  static const _verifiedKey = 'or_premium_authoritative';
  static const _platformKey = 'or_premium_platform';
  static const _productKey = 'or_premium_product_id';
  static const _tokenKey = 'or_premium_purchase_token';
  static const _txnKey = 'or_premium_transaction_id';

  @override
  Future<bool> isPremiumActive() async => isActiveNow;

  @override
  bool get isActiveNow => _storage.getBool(_premiumKey) ?? false;

  @override
  bool get wasAuthoritativelyVerified =>
      _storage.getBool(_verifiedKey) ?? false;

  @override
  Future<PremiumPlanKind?> activePlan() async {
    final index = _storage.getInt(_planKey);
    if (index == null) return null;
    return PremiumPlanKind.values[index.clamp(0, 2)];
  }

  @override
  Future<void> activatePlan(
    PremiumPlanKind plan, {
    bool authoritative = false,
  }) async {
    await _storage.setBool(_premiumKey, true);
    await _storage.setInt(_planKey, plan.index);
    await _storage.setBool(_verifiedKey, authoritative);
  }

  @override
  Future<void> clearLocalPremiumAccess() async {
    await _storage.setBool(_premiumKey, false);
    await _storage.setBool(_verifiedKey, false);
  }

  @override
  Future<void> savePurchaseCredentials(
    PremiumPurchaseCredentials credentials,
  ) async {
    await _storage.setString(_platformKey, credentials.platform);
    await _storage.setString(_productKey, credentials.productId);
    await _storage.setString(_tokenKey, credentials.purchaseToken);
    if (credentials.transactionId != null) {
      await _storage.setString(_txnKey, credentials.transactionId!);
    }
  }

  @override
  PremiumPurchaseCredentials? readPurchaseCredentials() {
    final platform = _storage.getString(_platformKey);
    final productId = _storage.getString(_productKey);
    final token = _storage.getString(_tokenKey);
    if (platform == null || productId == null || token == null) return null;
    return PremiumPurchaseCredentials(
      platform: platform,
      productId: productId,
      purchaseToken: token,
      transactionId: _storage.getString(_txnKey),
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
