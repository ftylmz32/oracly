/// OR-1100 — Settings repository backed by SharedPreferences.
library;

import '../../../features/companion/models/or_chat_output_mode.dart';
import '../../../features/premium/models/personalization_models.dart';
import '../../personality/or_response_depth.dart';
import '../../audio/oracly_atmosphere_palette.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../l10n/app_locale.dart';
import '../../theme/app_appearance.dart';
import '../../voice/or_speech_speed.dart';
import '../../voice/oracly_voice_id.dart';
import '../datasources/local_storage.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._storage);

  final LocalStorage _storage;

  static const _darkKey = 'settings_dark';
  static const _appearanceKey = 'settings_appearance';
  static const _langKey = 'settings_language';
  static const _notifKey = 'settings_notifications';
  static const _soundKey = 'settings_sound';
  static const _hapticKey = 'settings_haptic';
  static const _ambientMusicKey = 'settings_ambient_music';
  static const _voiceRepliesKey = 'settings_voice_replies';
  static const _depthKey = OrResponseDepth.storageKey;
  static const _atmosphereKey = 'settings_atmosphere_sign';
  static const _particleKey = 'settings_particles';
  static const _animKey = 'settings_animation';
  static const _aiKey = 'settings_ai_personality';
  static const _orVoiceKey = 'settings_or_voice';
  static const _orSpeechSpeedKey = 'settings_or_speech_speed';
  static const _themeKey = 'settings_theme';
  static const _premiumKey = 'or_premium_active';
  static const _streakKey = 'profile_streak';
  static const _readingsKey = 'profile_readings';
  static const _spiritKey = 'profile_spiritual';
  static const _deckKey = 'profile_favorite_deck';
  static const _analyticsKey = 'settings_analytics';

  @override
  Future<PersonalizationSettings> load() async {
    final legacyDark = _storage.getBool(_darkKey) ?? true;
    final storedRaw = _storage.getString(_appearanceKey);
    final appearance = AppAppearanceModeX.fromStorage(
      storedRaw,
      legacyDark: legacyDark,
    );
    // Migrate light/system → dark for v1 without deleting theme architecture.
    if (!AppAppearanceModeX.lightModeUserSelectable &&
        storedRaw != null &&
        storedRaw != AppAppearanceMode.dark.name) {
      await _storage.setString(_appearanceKey, AppAppearanceMode.dark.name);
      await _storage.setBool(_darkKey, true);
    } else if (!AppAppearanceModeX.lightModeUserSelectable &&
        storedRaw == null &&
        legacyDark == false) {
      await _storage.setString(_appearanceKey, AppAppearanceMode.dark.name);
      await _storage.setBool(_darkKey, true);
    }
    final voiceReplies = _readVoiceRepliesEnabled();
    final outputMode = _readOutputMode(voiceReplies);
    return PersonalizationSettings(
      appearanceMode: appearance,
      darkAppearance: appearance != AppAppearanceMode.light,
      language: AppLocale.resolvePreferred(
        stored: _storage.getString(_langKey),
        device: AppLocale.readDeviceLocale(),
      ),
      notificationsEnabled: _storage.getBool(_notifKey) ?? false,
      soundEnabled: _storage.getBool(_soundKey) ?? true,
      hapticEnabled: _storage.getBool(_hapticKey) ?? true,
      ambientMusicEnabled: _storage.getBool(_ambientMusicKey) ?? false,
      orOutputMode: outputMode.wire,
      voiceRepliesEnabled: outputMode.isVoice,
      orResponseDepth: OrResponseDepth.parse(_storage.getString(_depthKey)),
      atmosphereSign:
          OraclyAtmospherePalette.parse(_storage.getString(_atmosphereKey)),
      particleIntensity: ParticleIntensity.values[
          (_storage.getInt(_particleKey) ?? 1).clamp(0, 2)],
      animationSpeed: AnimationSpeed
          .values[(_storage.getInt(_animKey) ?? 1).clamp(0, 2)],
      aiPersonality:
          AiPersonality.values[(_storage.getInt(_aiKey) ?? 0).clamp(0, 3)],
      orVoiceId: OraclyVoiceId.parse(_storage.getString(_orVoiceKey)).wire,
      orSpeechSpeed:
          OrSpeechSpeed.parse(_storage.getString(_orSpeechSpeedKey)),
      theme: AppThemeMode.values[(_storage.getInt(_themeKey) ?? 0).clamp(0, 3)],
      isPremium: _storage.getBool(_premiumKey) ?? false,
      currentStreak: _storage.getInt(_streakKey) ?? 0,
      totalReadings: _storage.getInt(_readingsKey) ?? 0,
      spiritualLevel: _storage.getDouble(_spiritKey) ?? 0.0,
      favoriteDeck: _storage.getString(_deckKey) ?? 'Rider-Waite',
      analyticsEnabled: _storage.getBool(_analyticsKey) ?? true,
    );
  }

  @override
  Future<void> save(PersonalizationSettings settings) async {
    final appearance =
        AppAppearanceModeX.coerceForProduction(settings.appearanceMode);
    await _storage.setString(_appearanceKey, appearance.name);
    await _storage.setBool(
      _darkKey,
      appearance != AppAppearanceMode.light,
    );
    await _storage.setString(_langKey, AppLocale.normalize(settings.language));
    await _storage.setBool(_notifKey, settings.notificationsEnabled);
    await _storage.setBool(_soundKey, settings.soundEnabled);
    await _storage.setBool(_hapticKey, settings.hapticEnabled);
    await _storage.setBool(_ambientMusicKey, settings.ambientMusicEnabled);
    final output = _normalizedOutput(settings);
    await _storage.setBool(_voiceRepliesKey, output.isVoice);
    await _storage.setString(OrChatOutputMode.storageKey, output.wire);
    await _storage.setString(_depthKey, settings.orResponseDepth.name);
    await _storage.setString(_atmosphereKey, settings.atmosphereSign.name);
    await _storage.setInt(_particleKey, settings.particleIntensity.index);
    await _storage.setInt(_animKey, settings.animationSpeed.index);
    await _storage.setInt(_aiKey, settings.aiPersonality.index);
    await _storage.setString(_orVoiceKey, settings.orVoiceId);
    await _storage.setString(_orSpeechSpeedKey, settings.orSpeechSpeed.wire);
    await _storage.setInt(_themeKey, settings.theme.index);
    await _storage.setInt(_streakKey, settings.currentStreak);
    await _storage.setInt(_readingsKey, settings.totalReadings);
    await _storage.setDouble(_spiritKey, settings.spiritualLevel);
    await _storage.setString(_deckKey, settings.favoriteDeck);
    await _storage.setBool(_analyticsKey, settings.analyticsEnabled);
  }

  OrChatOutputMode _normalizedOutput(PersonalizationSettings settings) {
    final parsed = OrChatOutputMode.fromStorage(settings.orOutputMode);
    if (parsed != OrChatOutputMode.text) return parsed;
    return settings.voiceRepliesEnabled
        ? OrChatOutputMode.voice
        : OrChatOutputMode.text;
  }

  OrChatOutputMode _readOutputMode(bool voiceRepliesFallback) {
    final raw = _storage.getString(OrChatOutputMode.storageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      return OrChatOutputMode.fromStorage(raw);
    }
    return voiceRepliesFallback
        ? OrChatOutputMode.voice
        : OrChatOutputMode.text;
  }

  bool _readVoiceRepliesEnabled() {
    final stored = _storage.getBool(_voiceRepliesKey);
    if (stored != null) return stored;
    final legacy = _storage.getString(OrChatOutputMode.storageKey);
    return OrChatOutputMode.fromStorage(legacy).isVoice;
  }
}
