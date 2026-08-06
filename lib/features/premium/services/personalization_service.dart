/// OR-1090 — Persistence for personalization and premium state.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement_models.dart';
import '../models/personalization_models.dart';
import '../models/premium_models.dart';

class PersonalizationService {
  PersonalizationService._();
  static final PersonalizationService instance = PersonalizationService._();

  static const _premiumKey = 'or_premium_active';
  static const _planKey = 'or_premium_plan';
  static const _darkKey = 'settings_dark';
  static const _langKey = 'settings_language';
  static const _notifKey = 'settings_notifications';
  static const _soundKey = 'settings_sound';
  static const _hapticKey = 'settings_haptic';
  static const _particleKey = 'settings_particles';
  static const _animKey = 'settings_animation';
  static const _aiKey = 'settings_ai_personality';
  static const _themeKey = 'settings_theme';
  static const _streakKey = 'profile_streak';
  static const _readingsKey = 'profile_readings';
  static const _spiritKey = 'profile_spiritual';
  static const _deckKey = 'profile_favorite_deck';
  static const _achievementsKey = 'profile_achievements';

  Future<PersonalizationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PersonalizationSettings(
      darkAppearance: prefs.getBool(_darkKey) ?? true,
      language: prefs.getString(_langKey) ?? 'Türkçe',
      notificationsEnabled: prefs.getBool(_notifKey) ?? true,
      soundEnabled: prefs.getBool(_soundKey) ?? true,
      hapticEnabled: prefs.getBool(_hapticKey) ?? true,
      particleIntensity: ParticleIntensity.values[
          (prefs.getInt(_particleKey) ?? 1).clamp(0, 2)],
      animationSpeed: AnimationSpeed
          .values[(prefs.getInt(_animKey) ?? 1).clamp(0, 2)],
      aiPersonality: AiPersonality
          .values[(prefs.getInt(_aiKey) ?? 0).clamp(0, 3)],
      theme: AppThemeMode.values[(prefs.getInt(_themeKey) ?? 0).clamp(0, 3)],
      isPremium: prefs.getBool(_premiumKey) ?? false,
      currentStreak: prefs.getInt(_streakKey) ?? 3,
      totalReadings: prefs.getInt(_readingsKey) ?? 12,
      spiritualLevel: prefs.getDouble(_spiritKey) ?? 0.72,
      favoriteDeck: prefs.getString(_deckKey) ?? 'Rider-Waite',
    );
  }

  Future<void> save(PersonalizationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, settings.darkAppearance);
    await prefs.setString(_langKey, settings.language);
    await prefs.setBool(_notifKey, settings.notificationsEnabled);
    await prefs.setBool(_soundKey, settings.soundEnabled);
    await prefs.setBool(_hapticKey, settings.hapticEnabled);
    await prefs.setInt(_particleKey, settings.particleIntensity.index);
    await prefs.setInt(_animKey, settings.animationSpeed.index);
    await prefs.setInt(_aiKey, settings.aiPersonality.index);
    await prefs.setInt(_themeKey, settings.theme.index);
    await prefs.setBool(_premiumKey, settings.isPremium);
    await prefs.setInt(_streakKey, settings.currentStreak);
    await prefs.setInt(_readingsKey, settings.totalReadings);
    await prefs.setDouble(_spiritKey, settings.spiritualLevel);
    await prefs.setString(_deckKey, settings.favoriteDeck);
  }

  Future<PremiumPlanType?> activePlan() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_planKey);
    if (index == null) return null;
    return PremiumPlanType.values[index.clamp(0, 2)];
  }

  Future<void> activatePremium(PremiumPlanType plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, true);
    await prefs.setInt(_planKey, plan.index);
    await unlockAchievement(AchievementId.firstPremium.key);
  }

  Future<Set<String>> unlockedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_achievementsKey)?.toSet() ??
        {'first_reading', 'streak_7'};
  }

  Future<void> unlockAchievement(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_achievementsKey) ?? [];
    if (!current.contains(key)) {
      current.add(key);
      await prefs.setStringList(_achievementsKey, current);
    }
  }

  Future<List<Achievement>> loadAchievements() async {
    final keys = await unlockedAchievements();
    return AchievementCatalogue.defaults(unlockedKeys: keys);
  }
}
