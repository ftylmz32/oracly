/// OR-1100 — Mock premium repository.
library;

import '../../copy/premium_copy.dart';
import '../../domain/models/premium_plan.dart';
import '../../domain/repositories/premium_repository.dart';
import '../datasources/local_storage.dart';

class MockPremiumRepository implements PremiumRepository {
  MockPremiumRepository(this._storage);

  final LocalStorage _storage;
  static const _premiumKey = 'or_premium_active';
  static const _planKey = 'or_premium_plan';

  @override
  Future<bool> isPremiumActive() async =>
      _storage.getBool(_premiumKey) ?? false;

  @override
  Future<PremiumPlanKind?> activePlan() async {
    final index = _storage.getInt(_planKey);
    if (index == null) return null;
    return PremiumPlanKind.values[index.clamp(0, 2)];
  }

  @override
  Future<void> activatePlan(PremiumPlanKind plan) async {
    await _storage.setBool(_premiumKey, true);
    await _storage.setInt(_planKey, plan.index);
  }

  @override
  Future<List<PremiumPlanModel>> getPlans() async {
    final active = await activePlan();
    return [
      PremiumPlanModel(
        kind: PremiumPlanKind.monthly,
        label: 'Aylık',
        price: '₺149,99/ay',
        subtitle: PremiumCopy.planMonthlySubtitle,
        isActive: active == PremiumPlanKind.monthly,
      ),
      PremiumPlanModel(
        kind: PremiumPlanKind.yearly,
        label: 'Yıllık',
        price: '₺899,99/yıl',
        subtitle: PremiumCopy.planYearlySubtitle,
        isActive: active == PremiumPlanKind.yearly,
      ),
      PremiumPlanModel(
        kind: PremiumPlanKind.lifetime,
        label: 'Ömür Boyu',
        price: '₺2.499,99',
        subtitle: PremiumCopy.planLifetimeSubtitle,
        isActive: active == PremiumPlanKind.lifetime,
      ),
    ];
  }
}
