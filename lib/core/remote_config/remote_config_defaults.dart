/// Local safe defaults — app works fully without remote config.
library;

import '../experience/domain/models/experience_feature_flags.dart';
import '../feature_flags/product_feature_flags.dart';
import 'remote_config_snapshot.dart';

abstract final class RemoteConfigDefaults {
  RemoteConfigDefaults._();

  static final snapshot = RemoteConfigSnapshot(
    configVersion: 1,
    minAppVersion: null,
    dailyMessageWeights: {
      'theme_evidence': 0.45,
      'theme_lines': 0.35,
      'catalogue': 0.20,
    },
    gemHistoryDisplayLimit: 4,
    featureFlags: {
      ...ExperienceFeatureFlags.defaults(),
      ...ProductFeatureFlags.defaults(),
    },
    copyOverrides: {},
    experiments: {},
    animationIntensityCap: 'medium',
    notificationCadenceHours: 24,
    notificationDailyHour: 10,
  );
}
