/// OR-1090 — Personalization settings model.
library;

import '../../../core/personality/or_response_depth.dart';
import '../../../core/theme/app_appearance.dart';
import '../../../core/voice/or_speech_speed.dart';
import '../../birth_chart/models/zodiac_sign_id.dart';

enum AppThemeMode { cosmic, amethyst, midnight, aurora }

enum AiPersonality { mystical, gentle, direct, poetic }

enum AnimationSpeed { slow, normal, fast }

enum ParticleIntensity { low, medium, high }

class PersonalizationSettings {
  const PersonalizationSettings({
    this.darkAppearance = true,
    this.appearanceMode = AppAppearanceMode.dark,
    this.language = 'tr',
    this.notificationsEnabled = false,
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.ambientMusicEnabled = false,
    this.orOutputMode = 'text',
    this.voiceRepliesEnabled = false,
    this.orResponseDepth = OrResponseDepth.fallback,
    this.atmosphereSign = ZodiacSignId.cancer,
    this.particleIntensity = ParticleIntensity.medium,
    this.animationSpeed = AnimationSpeed.normal,
    this.aiPersonality = AiPersonality.mystical,
    this.orVoiceId = 'warm',
    this.orSpeechSpeed = OrSpeechSpeed.normal,
    this.theme = AppThemeMode.cosmic,
    this.isPremium = false,
    this.currentStreak = 0,
    this.totalReadings = 0,
    this.spiritualLevel = 0.0,
    this.favoriteDeck = 'Rider-Waite',
    this.analyticsEnabled = true,
  });

  /// Legacy bool — kept in sync with [appearanceMode] for older readers.
  final bool darkAppearance;
  final AppAppearanceMode appearanceMode;
  final String language;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool hapticEnabled;

  /// Atmospheric music — default OFF; independent from SFX.
  final bool ambientMusicEnabled;

  /// OR autoplay (text|voice|conversation); voiceRepliesEnabled mirrors it.
  final String orOutputMode;
  final bool voiceRepliesEnabled;

  /// Reply length only. Personality is unchanged.
  final OrResponseDepth orResponseDepth;

  /// Symbolic burç atmosphere (not a scientific claim).
  final ZodiacSignId atmosphereSign;
  final ParticleIntensity particleIntensity;
  final AnimationSpeed animationSpeed;
  final AiPersonality aiPersonality;

  /// OR timbre identity. Personality is a separate delivery layer.
  final String orVoiceId;

  /// Speech tempo. Default natural.
  final OrSpeechSpeed orSpeechSpeed;
  final AppThemeMode theme;
  final bool isPremium;
  final int currentStreak;
  final int totalReadings;
  final double spiritualLevel;
  final String favoriteDeck;

  /// Anonymous product analytics — opt-out in Privacy settings.
  final bool analyticsEnabled;

  PersonalizationSettings copyWith({
    bool? darkAppearance,
    AppAppearanceMode? appearanceMode,
    String? language,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? ambientMusicEnabled,
    String? orOutputMode,
    bool? voiceRepliesEnabled,
    OrResponseDepth? orResponseDepth,
    ZodiacSignId? atmosphereSign,
    ParticleIntensity? particleIntensity,
    AnimationSpeed? animationSpeed,
    AiPersonality? aiPersonality,
    String? orVoiceId,
    OrSpeechSpeed? orSpeechSpeed,
    AppThemeMode? theme,
    bool? isPremium,
    int? currentStreak,
    int? totalReadings,
    double? spiritualLevel,
    String? favoriteDeck,
    bool? analyticsEnabled,
  }) {
    // Legacy darkAppearance-only writes must move appearanceMode too.
    final mode = appearanceMode ??
        (darkAppearance == null
            ? this.appearanceMode
            : (darkAppearance
                ? AppAppearanceMode.dark
                : AppAppearanceMode.light));
    final output = orOutputMode ??
        (voiceRepliesEnabled == null
            ? this.orOutputMode
            : (voiceRepliesEnabled
                ? (this.orOutputMode == 'conversation'
                    ? 'conversation'
                    : 'voice')
                : 'text'));
    return PersonalizationSettings(
      appearanceMode: mode,
      darkAppearance: darkAppearance ?? (mode != AppAppearanceMode.light),
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      ambientMusicEnabled: ambientMusicEnabled ?? this.ambientMusicEnabled,
      orOutputMode: output,
      voiceRepliesEnabled: output != 'text',
      orResponseDepth: orResponseDepth ?? this.orResponseDepth,
      atmosphereSign: atmosphereSign ?? this.atmosphereSign,
      particleIntensity: particleIntensity ?? this.particleIntensity,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      aiPersonality: aiPersonality ?? this.aiPersonality,
      orVoiceId: orVoiceId ?? this.orVoiceId,
      orSpeechSpeed: orSpeechSpeed ?? this.orSpeechSpeed,
      theme: theme ?? this.theme,
      isPremium: isPremium ?? this.isPremium,
      currentStreak: currentStreak ?? this.currentStreak,
      totalReadings: totalReadings ?? this.totalReadings,
      spiritualLevel: spiritualLevel ?? this.spiritualLevel,
      favoriteDeck: favoriteDeck ?? this.favoriteDeck,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }
}
