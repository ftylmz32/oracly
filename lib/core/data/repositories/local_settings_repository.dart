/// OR-1100 — Settings repository backed by SharedPreferences.
library;

import '../../../features/premium/models/personalization_models.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local_storage.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._storage);

  final LocalStorage _storage;

  static const _darkKey = 'settings_dark';
  static const _langKey = 'settings_language';
  static const _notifKey = 'settings_notifications';
  static const _soundKey = 'settings_sound';
  static const _hapticKey = 'settings_haptic';
  static const _particleKey = 'settings_particles';
  static const _animKey = 'settings_animation';
  static const _aiKey = 'settings_ai_personality';
  static const _themeKey = 'settings_theme';
  static const _premiumKey = 'or_premium_active';
  static const _streakKey = 'profile_streak';
  static const _readingsKey = 'profile_readings';
  static const _spiritKey = 'profile_spiritual';
  static const _deckKey = 'profile_favorite_deck';

  @override
  Future<PersonalizationSettings> load() async {
    return PersonalizationSettings(
      darkAppearance: _storage.getBool(_darkKey) ?? true,
      language: _storage.getString(_langKey) ?? 'Türkçe',
      notificationsEnabled: _storage.getBool(_notifKey) ?? true,
      soundEnabled: _storage.getBool(_soundKey) ?? true,
      hapticEnabled: _storage.getBool(_hapticKey) ?? true,
      particleIntensity: ParticleIntensity.values[
          (_storage.getInt(_particleKey) ?? 1).clamp(0, 2)],
      animationSpeed: AnimationSpeed
          .values[(_storage.getInt(_animKey) ?? 1).clamp(0, 2)],
      aiPersonality:
          AiPersonality.values[(_storage.getInt(_aiKey) ?? 0).clamp(0, 3)],
      theme: AppThemeMode.values[(_storage.getInt(_themeKey) ?? 0).clamp(0, 3)],
      isPremium: _storage.getBool(_premiumKey) ?? false,
      currentStreak: _storage.getInt(_streakKey) ?? 0,
      totalReadings: _storage.getInt(_readingsKey) ?? 0,
      spiritualLevel: _storage.getDouble(_spiritKey) ?? 0.0,
      favoriteDeck: _storage.getString(_deckKey) ?? 'Rider-Waite',
    );
  }

  @override
  Future<void> save(PersonalizationSettings settings) async {
    await _storage.setBool(_darkKey, settings.darkAppearance);
    await _storage.setString(_langKey, settings.language);
    await _storage.setBool(_notifKey, settings.notificationsEnabled);
    await _storage.setBool(_soundKey, settings.soundEnabled);
    await _storage.setBool(_hapticKey, settings.hapticEnabled);
    await _storage.setInt(_particleKey, settings.particleIntensity.index);
    await _storage.setInt(_animKey, settings.animationSpeed.index);
    await _storage.setInt(_aiKey, settings.aiPersonality.index);
    await _storage.setInt(_themeKey, settings.theme.index);
    await _storage.setBool(_premiumKey, settings.isPremium);
    await _storage.setInt(_streakKey, settings.currentStreak);
    await _storage.setInt(_readingsKey, settings.totalReadings);
    await _storage.setDouble(_spiritKey, settings.spiritualLevel);
    await _storage.setString(_deckKey, settings.favoriteDeck);
  }
}
