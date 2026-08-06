/// OR-1100 — User profile domain model.
library;

class UserProfileModel {
  const UserProfileModel({
    this.name = '',
    this.job = '',
    this.interests = const [],
    this.goals = const [],
    this.currentStreak = 0,
    this.totalReadings = 0,
    this.spiritualLevel = 0,
    this.favoriteDeckId = 'rider-waite',
    this.isPremium = false,
    this.unlockedAchievementKeys = const [],
  });

  final String name;
  final String job;
  final List<String> interests;
  final List<String> goals;
  final int currentStreak;
  final int totalReadings;
  final double spiritualLevel;
  final String favoriteDeckId;
  final bool isPremium;
  final List<String> unlockedAchievementKeys;

  UserProfileModel copyWith({
    String? name,
    String? job,
    List<String>? interests,
    List<String>? goals,
    int? currentStreak,
    int? totalReadings,
    double? spiritualLevel,
    String? favoriteDeckId,
    bool? isPremium,
    List<String>? unlockedAchievementKeys,
  }) {
    return UserProfileModel(
      name: name ?? this.name,
      job: job ?? this.job,
      interests: interests ?? this.interests,
      goals: goals ?? this.goals,
      currentStreak: currentStreak ?? this.currentStreak,
      totalReadings: totalReadings ?? this.totalReadings,
      spiritualLevel: spiritualLevel ?? this.spiritualLevel,
      favoriteDeckId: favoriteDeckId ?? this.favoriteDeckId,
      isPremium: isPremium ?? this.isPremium,
      unlockedAchievementKeys:
          unlockedAchievementKeys ?? this.unlockedAchievementKeys,
    );
  }
}
