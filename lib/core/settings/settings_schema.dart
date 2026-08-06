/// OR-438 — Extensible settings keys for module-owned preferences.
library;

/// Stable preference keys — add module keys here before UI surfaces them.
abstract final class SettingsSchema {
  SettingsSchema._();

  // ── Global (existing PersonalizationSettings) ───────────────────────────
  static const darkAppearance = 'dark_appearance';
  static const language = 'language';
  static const notificationsEnabled = 'notifications_enabled';
  static const soundEnabled = 'sound_enabled';
  static const hapticEnabled = 'haptic_enabled';
  static const particleIntensity = 'particle_intensity';
  static const animationSpeed = 'animation_speed';
  static const aiPersonality = 'ai_personality';
  static const theme = 'theme';

  // ── Module extension slots (persist when modules ship) ──────────────────
  static const moonNotifications = 'moon_notifications';
  static const manifestationReminders = 'manifestation_reminders';
  static const numerologyProfile = 'numerology_profile';
  static const dreamJournalSync = 'dream_journal_sync';
  static const astrologyBirthChart = 'astrology_birth_chart';

  /// All keys currently defined — useful for migration and debug panels.
  static const all = [
    darkAppearance,
    language,
    notificationsEnabled,
    soundEnabled,
    hapticEnabled,
    particleIntensity,
    animationSpeed,
    aiPersonality,
    theme,
    moonNotifications,
    manifestationReminders,
    numerologyProfile,
    dreamJournalSync,
    astrologyBirthChart,
  ];
}
