/// Safe remote product configuration — local defaults always win on failure.
library;

class RemoteConfigSnapshot {
  const RemoteConfigSnapshot({
    required this.configVersion,
    this.minAppVersion,
    required this.dailyMessageWeights,
    required this.gemHistoryDisplayLimit,
    required this.featureFlags,
    required this.copyOverrides,
    required this.experiments,
    required this.animationIntensityCap,
    required this.notificationCadenceHours,
    required this.notificationDailyHour,
  });

  final int configVersion;
  final String? minAppVersion;
  final Map<String, double> dailyMessageWeights;
  final int gemHistoryDisplayLimit;
  final Map<String, bool> featureFlags;
  final Map<String, String> copyOverrides;
  final Map<String, String> experiments;
  final String animationIntensityCap;
  final int notificationCadenceHours;
  final int notificationDailyHour;

  RemoteConfigSnapshot merge(RemoteConfigSnapshot overlay) {
    return RemoteConfigSnapshot(
      configVersion: overlay.configVersion,
      minAppVersion: overlay.minAppVersion ?? minAppVersion,
      dailyMessageWeights: overlay.dailyMessageWeights.isEmpty
          ? dailyMessageWeights
          : {...dailyMessageWeights, ...overlay.dailyMessageWeights},
      gemHistoryDisplayLimit: overlay.gemHistoryDisplayLimit,
      featureFlags: {...featureFlags, ...overlay.featureFlags},
      copyOverrides: {...copyOverrides, ...overlay.copyOverrides},
      experiments: {...experiments, ...overlay.experiments},
      animationIntensityCap: overlay.animationIntensityCap,
      notificationCadenceHours: overlay.notificationCadenceHours,
      notificationDailyHour: overlay.notificationDailyHour,
    );
  }

  bool featureEnabled(String key, {bool fallback = true}) =>
      featureFlags[key] ?? fallback;

  String? experiment(String key) => experiments[key];

  String? copy(String key) => copyOverrides[key];

  /// Safe keys only — revalidated before reactivation.
  Map<String, Object?> toPersistedJson() => {
        'config_version': configVersion,
        if (minAppVersion != null) 'min_app_version': minAppVersion,
        'daily_message_weights': dailyMessageWeights,
        'gem_history_display_limit': gemHistoryDisplayLimit,
        'feature_flags': featureFlags,
        'copy_overrides': copyOverrides,
        'experiments': experiments,
        'animation_intensity_cap': animationIntensityCap,
        'notification_cadence_hours': notificationCadenceHours,
        'notification_daily_hour': notificationDailyHour,
      };
}
