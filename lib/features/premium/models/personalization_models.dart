/// OR-1090 — Personalization settings model.
library;

enum AppThemeMode { cosmic, amethyst, midnight, aurora }

enum AiPersonality { mystical, gentle, direct, poetic }

enum AnimationSpeed { slow, normal, fast }

enum ParticleIntensity { low, medium, high }

class PersonalizationSettings {
  const PersonalizationSettings({
    this.darkAppearance = true,
    this.language = 'Türkçe',
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.particleIntensity = ParticleIntensity.medium,
    this.animationSpeed = AnimationSpeed.normal,
    this.aiPersonality = AiPersonality.mystical,
    this.theme = AppThemeMode.cosmic,
    this.isPremium = false,
    this.currentStreak = 3,
    this.totalReadings = 12,
    this.spiritualLevel = 0.72,
    this.favoriteDeck = 'Rider-Waite',
  });

  final bool darkAppearance;
  final String language;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool hapticEnabled;
  final ParticleIntensity particleIntensity;
  final AnimationSpeed animationSpeed;
  final AiPersonality aiPersonality;
  final AppThemeMode theme;
  final bool isPremium;
  final int currentStreak;
  final int totalReadings;
  final double spiritualLevel;
  final String favoriteDeck;

  PersonalizationSettings copyWith({
    bool? darkAppearance,
    String? language,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? hapticEnabled,
    ParticleIntensity? particleIntensity,
    AnimationSpeed? animationSpeed,
    AiPersonality? aiPersonality,
    AppThemeMode? theme,
    bool? isPremium,
    int? currentStreak,
    int? totalReadings,
    double? spiritualLevel,
    String? favoriteDeck,
  }) {
    return PersonalizationSettings(
      darkAppearance: darkAppearance ?? this.darkAppearance,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      particleIntensity: particleIntensity ?? this.particleIntensity,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      aiPersonality: aiPersonality ?? this.aiPersonality,
      theme: theme ?? this.theme,
      isPremium: isPremium ?? this.isPremium,
      currentStreak: currentStreak ?? this.currentStreak,
      totalReadings: totalReadings ?? this.totalReadings,
      spiritualLevel: spiritualLevel ?? this.spiritualLevel,
      favoriteDeck: favoriteDeck ?? this.favoriteDeck,
    );
  }

  static const labels = {
    'appearance': 'Görünüm',
    'language': 'Dil',
    'notifications': 'Bildirimler',
    'sound': 'Ses',
    'haptic': 'Dokunsal Geri Bildirim',
    'particles': 'Parçacık Yoğunluğu',
    'animation': 'Animasyon Hızı',
    'aiPersonality': 'AI Kişiliği',
    'theme': 'Tema Seçimi',
    'privacy': 'Gizlilik',
    'account': 'Hesap',
  };
}
