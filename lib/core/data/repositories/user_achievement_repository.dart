/// OR-1130 — Achievement repository delegating to UserRepository.
library;

import '../../domain/models/achievement.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../../domain/repositories/user_repository.dart';

class UserAchievementRepository implements AchievementRepository {
  UserAchievementRepository(this._userRepository);

  final UserRepository _userRepository;

  @override
  Future<List<AchievementModel>> getAll() => _userRepository.getAchievements();

  @override
  Future<void> unlock(String key) => _userRepository.unlockAchievement(key);

  @override
  Future<void> sync() async {}
}
