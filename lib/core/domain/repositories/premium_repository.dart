/// OR-1100 — Premium repository interface.
library;

import '../models/premium_plan.dart';

abstract class PremiumRepository {
  Future<bool> isPremiumActive();
  Future<PremiumPlanKind?> activePlan();
  Future<void> activatePlan(PremiumPlanKind plan);
  Future<List<PremiumPlanModel>> getPlans();
}
