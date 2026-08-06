/// OR-1100 — Premium membership service.
library;

import '../domain/models/premium_plan.dart';
import '../domain/repositories/premium_repository.dart';
import '../domain/repositories/user_repository.dart';

class PremiumService {
  PremiumService(this._premium, this._user);

  final PremiumRepository _premium;
  final UserRepository _user;

  Future<bool> isActive() => _premium.isPremiumActive();

  Future<List<PremiumPlanModel>> getPlans() => _premium.getPlans();

  Future<void> activate(PremiumPlanKind plan) async {
    await _premium.activatePlan(plan);
    final profile = await _user.getProfile();
    await _user.saveProfile(profile.copyWith(isPremium: true));
    await _user.unlockAchievement('first_premium');
  }
}
