/// OR-1120 — SharedPreferences onboarding flag.
library;

import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/local_storage.dart';

class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository(this._storage);

  static const String completedKey = 'onboarding_completed';

  final LocalStorage _storage;

  @override
  Future<bool> isCompleted() async {
    return _storage.getBool(completedKey) ?? false;
  }

  @override
  Future<void> markCompleted() async {
    await _storage.setBool(completedKey, true);
  }
}
